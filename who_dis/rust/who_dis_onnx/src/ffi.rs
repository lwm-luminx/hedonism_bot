use std::ffi::CString;
use std::os::raw::{c_char, c_int, c_void};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

pub type StatusCallback = extern "C" fn(status: *const c_char, context: *mut c_void);

pub struct WorkerHandle {
    running: Arc<AtomicBool>,
}

/// Offline validation of the Rust ML runtime.
#[no_mangle]
pub extern "C" fn who_dis_check() -> c_int {
    // Validate that ONNX Runtime initialization succeeds
    match ort::init().with_name("who_dis_check").build() {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Starts the who_dis background worker with the provided JSON configuration.
#[no_mangle]
pub extern "C" fn who_dis_start(
    _config_json: *const c_char,
    status_cb: Option<StatusCallback>,
    context: *mut c_void,
) -> *mut WorkerHandle {
    let running = Arc::new(AtomicBool::new(true));
    let running_clone = running.clone();
    let ctx_addr = context as usize;

    // Spawn background worker thread
    thread::spawn(move || {
        // Emit COGSWORTH_READY status
        if let Some(cb) = status_cb {
            let ready = CString::new("COGSWORTH_READY").unwrap();
            cb(ready.as_ptr(), ctx_addr as *mut c_void);
        }

        while running_clone.load(Ordering::Relaxed) {
            thread::sleep(Duration::from_millis(500));
        }
    });

    Box::into_raw(Box::new(WorkerHandle { running }))
}

/// Signals the background worker to stop and deallocates its handle.
#[no_mangle]
pub extern "C" fn who_dis_stop(handle: *mut WorkerHandle) {
    if !handle.is_null() {
        let handle = unsafe { Box::from_raw(handle) };
        handle.running.store(false, Ordering::Relaxed);
    }
}
