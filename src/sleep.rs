#![no_main]
#![no_std]

use core::ffi::c_char;
use core::ffi::c_int;
use core::ffi::c_long;

use core::ptr::NonNull;

use core::time::Duration;

const EXIT_SUCCESS: c_int = 0;
const EXIT_FAILURE: c_int = 1;

const SYS_WRITE: c_long = 1;
const SYS_EXIT: c_long = 60;
const SYS_NANOSLEEP: c_long = 35;

/// Halts the CPU until the next interrupt arrives.
#[inline]
pub fn hlt() {
    unsafe {
        core::arch::asm!("hlt", options(nomem, nostack, preserves_flags));
    }
}

/// Executes the `nop` instructions, which performs no operation (i.e. does nothing).
///
/// This operation is useful to work around the LLVM bug that endless loops are illegally
/// optimized away (see [the issue](https://github.com/rust-lang/rust/issues/28728)). By invoking this
/// instruction (which is marked as volatile), the compiler should no longer optimize the
/// endless loop away.
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

fn sleep(dur: Duration) {
    #[repr(C)]
    struct Timespec {
        tv_sec: c_long,
        tv_nsec: c_long,
    }

    const SECOND: u128 = 1_000_000_000;

    let nanos = dur.as_nanos();
    let secs = nanos / SECOND;
    let nanos = nanos % SECOND;

    let ts = Timespec {
        tv_sec: secs as _,
        tv_nsec: nanos as _,
    };

    unsafe { syscall2(SYS_NANOSLEEP, (&raw const ts) as _, 0) };
}

#[unsafe(no_mangle)]
extern "C" fn exit(code: c_int) -> ! {
    unsafe { syscall1(SYS_EXIT, code as c_long) };
    loop {
        //this effectively inreachable, but we need
        //to please clippy, and return type I guess
        hlt();
    }
}

fn print(s: &str) {
    unsafe {
        syscall3(SYS_WRITE, 1, s.as_ptr().addr() as c_long, s.len() as c_long);
    }
}

#[unsafe(no_mangle)]
unsafe extern "C" fn main(argc: c_int, argv: *const *const c_char) -> c_int {
    match unsafe {
        main_impl(core::slice::from_raw_parts(
            argv as *const NonNull<c_char>,
            argc as usize,
        ))
    } {
        Ok(_) => EXIT_SUCCESS,
        Err(_) => EXIT_FAILURE,
    }
}

// We need strlen because rustc on opt-level 2+ tries to replace
// strlen-like code with strlen call
#[unsafe(no_mangle)]
unsafe extern "C" fn strlen(s: NonNull<c_char>) -> usize {
    let mut cursor = s;
    unsafe {
        while cursor.read() != 0 {
            cursor = cursor.add(1);
        }
    }

    unsafe { cursor.offset_from(s) as usize }
}

unsafe fn bytes_from_nullterminated<'a>(ptr: NonNull<c_char>) -> &'a [u8] {
    let len = unsafe { strlen(ptr) };

    unsafe { core::slice::from_raw_parts(ptr.cast::<u8>().as_ptr(), len) }
}

unsafe fn main_impl(args: &[NonNull<c_char>]) -> Result<(), ()> {
    let Some(&sleep_duration) = args.get(1) else {
        print("Usage: sleep SECONDS\n");
        return Err(());
    };

    let sleep_duration_bytes = unsafe { bytes_from_nullterminated(sleep_duration) };

    let Ok(sleep_duration_str) = str::from_utf8(sleep_duration_bytes) else {
        print("I dont work with non-UTF8 stuff\n");
        return Err(());
    };

    let sleep_duration_int: u32 = sleep_duration_str
        .parse()
        .inspect_err(|_| print("parameter should be integer\n"))
        .map_err(|_| ())?;

    sleep(Duration::from_secs(sleep_duration_int as _));
    Ok(())
}

#[unsafe(no_mangle)]
#[unsafe(naked)]
extern "C" fn _start() {
    core::arch::naked_asm!(
        "xor ebp, ebp",
        "mov rdi, [rsp]",
        "lea rsi, [rsp + 8]",
        "and rsp, -16",
        "call main",
        "mov rdi, rax",
        "call exit"
    )
}
