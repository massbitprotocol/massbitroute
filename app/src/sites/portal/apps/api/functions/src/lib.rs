use libc::c_void;
use std::ffi::CString;

mod binding;

/**
 * ngx_link_func_init_cycle
 * ngx_link_func_exit_cycle
 * は必須
 */
#[no_mangle]
pub extern "C" fn ngx_link_func_init_cycle(cycle: *mut binding::ngx_link_func_cycle_t) {
    unsafe {
        binding::ngx_link_func_cyc_log_info(
            cycle,
            CString::new("starting application").unwrap().as_ptr() as *const i8,
        );
    }
}

#[no_mangle]
pub extern "C" fn ngx_link_func_exit_cycle(cycle: *mut binding::ngx_link_func_cycle_t) {
    unsafe {
        binding::ngx_link_func_cyc_log_info(
            cycle,
            CString::new("Shutting down application").unwrap().as_ptr() as *const i8,
        );
    }
}

#[no_mangle]
pub extern "C" fn my_app_simple_get_greeting(ctx: *mut binding::ngx_link_func_ctx_t) {
    let msg = "greeting from ngx_link_func testing with rust hehe\n";
    unsafe {
        binding::ngx_link_func_log_info(
            ctx,
            CString::new("hogehoge").unwrap().as_ptr() as *const i8,
        );

        binding::ngx_link_func_write_resp(
            ctx,
            200,
            CString::new("200 OK").unwrap().as_ptr() as *const i8,
            CString::new("text/plain").unwrap().as_ptr() as *const i8,
            CString::new(msg).unwrap().as_ptr() as *const i8,
            msg.len(),
        );
    }
}
