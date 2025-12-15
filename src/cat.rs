#![no_main]
#![no_std]

use core::ffi::{c_char, c_int, c_long};
use core::ptr::NonNull;

const EXIT_SUCCESS: c_int = 0;
const EXIT_FAILURE: c_int = 1;

const SYS_READ: c_long = 0;
const SYS_WRITE: c_long = 1;
const SYS_OPEN: c_long = 2;
const SYS_CLOSE: c_long = 3;
const SYS_EXIT: c_long = 60;

const STDIN_FILENO: c_long = 0;
const STDOUT_FILENO: c_long = 1;
const STDERR_FILENO: c_long = 2;

const O_RDONLY: c_long = 0;

#[unsafe(no_mangle)]
pub unsafe extern "C" fn memset(dest: *mut u8, c: c_int, n: usize) -> *mut u8 {
    let mut i = 0;
    while i < n {
        *dest.add(i) = c as u8;
        i += 1;
    }
    dest
}

#[inline]
pub fn hlt() {
    unsafe {
        core::arch::asm!("hlt", options(nomem, nostack, preserves_flags));
    }
}

#[inline]
pub fn nop() {
    unsafe {
        core::arch::asm!("nop", options(nomem, nostack, preserves_flags));
    }
}

#[panic_handler]
fn on_panic(_info: &core::panic::PanicInfo) -> ! {
    loop {
        nop();
    }
}

#[unsafe(no_mangle)]
extern "C" fn rust_eh_personality() -> ! {
    loop {
        nop();
    }
}

unsafe fn syscall1(number: c_long, arg1: c_long) -> c_long {
    let result: c_long;
    unsafe {
        core::arch::asm!(
            "syscall",
            inlateout("rax") number => result,
            in("rdi") arg1,
            lateout("rcx") _,
            lateout("r11") _,
            options(nostack, preserves_flags)
        );
    }
    result
}

unsafe fn syscall2(number: c_long, arg1: c_long, arg2: c_long) -> c_long {
    let result: c_long;
    unsafe {
        core::arch::asm!(
            "syscall",
            inlateout("rax") number => result,
            in("rdi") arg1,
            in("rsi") arg2,
            lateout("rcx") _,
            lateout("r11") _,
            options(nostack, preserves_flags)
        );
    }
    result
}

unsafe fn syscall3(number: c_long, arg1: c_long, arg2: c_long, arg3: c_long) -> c_long {
    let result: c_long;
    unsafe {
        core::arch::asm!(
            "syscall",
            inlateout("rax") number => result,
            in("rdi") arg1,
            in("rsi") arg2,
            in("rdx") arg3,
            lateout("rcx") _,
            lateout("r11") _,
            options(nostack, preserves_flags)
        );
    }
    result
}

fn print_error(msg: &str) {
    unsafe {
        syscall3(
            SYS_WRITE,
            STDERR_FILENO,
            msg.as_ptr() as c_long,
            msg.len() as c_long,
        );
    }
}

unsafe fn cat_fd(fd: c_long) -> Result<(), ()> {
    const BUF_SIZE: usize = 4096;
    let mut buf = [0u8; BUF_SIZE];

    loop {
        let nread = syscall3(SYS_READ, fd, buf.as_mut_ptr() as c_long, BUF_SIZE as c_long);

        if nread < 0 {
            return Err(());
        }
        if nread == 0 {
            break;
        }

        let nwritten = syscall3(SYS_WRITE, STDOUT_FILENO, buf.as_ptr() as c_long, nread);
        if nwritten < 0 || nwritten != nread {
            return Err(()); // Write error
        }
    }
    Ok(())
}

fn open_and_cat(filename_ptr: *const c_char) -> Result<(), ()> {
    let fd = unsafe { syscall2(SYS_OPEN, filename_ptr as c_long, O_RDONLY) };
    if fd < 0 {
        return Err(());
    }

    let res = unsafe { cat_fd(fd) };
    unsafe { syscall1(SYS_CLOSE, fd) };
    res
}

#[unsafe(no_mangle)]
unsafe extern "C" fn main(argc: c_int, argv: *const *const c_char) -> c_int {
    let args =
        unsafe { core::slice::from_raw_parts(argv as *const NonNull<c_char>, argc as usize) };

    if args.len() < 2 {
        // No args: read from stdin
        if unsafe { cat_fd(STDIN_FILENO) }.is_err() {
            print_error("cat: read error on stdin\n");
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    }

    // Iterate over files
    for &arg_ptr in &args[1..] {
        if open_and_cat(arg_ptr.as_ptr()).is_err() {
            // Minimal error messaging: we don't have a formatted printer here easily
            // without pulling in more complexity or alloc, so we just say "error"
            // or we could print the filename if we had a way to determine its length
            // efficiently (strlen) which we do in sleep.rs, but let's keep it simple.
            print_error("cat: error opening or reading file\n");
            return EXIT_FAILURE;
        }
    }

    EXIT_SUCCESS
}

#[unsafe(no_mangle)]
extern "C" fn exit(code: c_int) -> ! {
    unsafe { syscall1(SYS_EXIT, code as c_long) };
    loop {
        hlt();
    }
}

#[unsafe(no_mangle)]
#[unsafe(naked)]
extern "C" fn _start() {
    core::arch::naked_asm!(
        "xor ebp, ebp",       // Clear frame pointer
        "mov rdi, [rsp]",     // argc
        "lea rsi, [rsp + 8]", // argv
        "and rsp, -16",       // Align stack
        "call main",
        "mov rdi, rax", // Return value of main -> exit code
        "call exit"
    )
}
