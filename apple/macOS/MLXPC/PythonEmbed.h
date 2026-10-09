#pragma once
// Runs exactly once on a dedicated thread; the XPC process owns interpreter lifetime.
typedef void (*CogsworthPythonOutput)(const char *line);
int CogsworthRunPython(const char *home, const char *configuration, CogsworthPythonOutput output, int checkOnly);

const char *CogsworthPythonCheckError(void);
