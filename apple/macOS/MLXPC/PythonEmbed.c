#include "PythonEmbed.h"
#include <Python.h>
#include <stdio.h>

static char check_error[2048];
const char *CogsworthPythonCheckError(void) { return check_error; }

static CogsworthPythonOutput emit_output;
static PyObject *emit(PyObject *self, PyObject *args) {
    const char *line;
    if (!PyArg_ParseTuple(args, "s", &line)) return NULL;
    if (emit_output) emit_output(line);
    Py_RETURN_NONE;
}
static PyMethodDef methods[] = {{"emit", emit, METH_VARARGS, "Send a worker status line to XPC."}, {NULL}};
static struct PyModuleDef module = {PyModuleDef_HEAD_INIT, "_cogsworth_xpc", NULL, -1, methods};
static PyObject *initialize_bridge(void) { return PyModule_Create(&module); }

int CogsworthRunPython(const char *home, const char *configuration, CogsworthPythonOutput output, int checkOnly) {
    emit_output = output;
    if (PyImport_AppendInittab("_cogsworth_xpc", initialize_bridge) == -1) return 1;
    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);
    config.install_signal_handlers = 0;
    config.write_bytecode = 0;
    config.parse_argv = 0;
    PyStatus status = PyConfig_SetBytesString(&config, &config.home, home);
    if (!PyStatus_Exception(status)) status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) return 2;
    PyObject *runtime = PyImport_ImportModule("hedonism.who_dis.xpc_runtime");
    PyObject *run = runtime ? PyObject_GetAttrString(runtime, checkOnly ? "check" : "run") : NULL;
    PyObject *argument = PyUnicode_FromString(configuration);
    PyObject *result = run && argument ? PyObject_CallFunctionObjArgs(run, argument, NULL) : NULL;
    int code = result ? 0 : 3;
    // Avoid exposing Python exceptions containing credentials over IPC.
    if (!result && checkOnly) {
        // The offline diagnostic has no credentials or network request. Preserve its
        // import failure so the package can be repaired without weakening the sandbox.
        PyObject *error = PyErr_GetRaisedException();
        PyObject *description = error ? PyObject_Str(error) : NULL;
        const char *message = description ? PyUnicode_AsUTF8(description) : NULL;
        snprintf(check_error, sizeof(check_error), "%s", message ? message : "Python initialization/import failed");
        Py_XDECREF(description); Py_XDECREF(error);
    }
    if (!result) PyErr_Clear();
    Py_XDECREF(result); Py_XDECREF(argument); Py_XDECREF(run); Py_XDECREF(runtime);
    // Native ML libraries may retain background threads. Tear down the XPC process,
    // rather than finalizing and reinitializing CPython in the same process.
    return code;
}
