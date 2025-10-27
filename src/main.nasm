%ifdef __Linux
    %define SYSCALL_EXIT 60
    %define SYSCALL_WRITE 1
    %define STDOUT 1 ; File descriptor 1 is stdout.
%elifdef __Darwin
    %define SYSCALL_EXIT 0x2000001
    %define SYSCALL_WRITE 0x2000004
    %define STDOUT 1 ; File descriptor 1 is stdout.
%else ; Windows
    ; We must call kernel32.dll functions
    extern ExitProcess
    extern WriteFile
    extern GetStdHandle
    %define STD_OUTPUT_HANDLE -11
%endif

[bits 64]

%define print_hello_var_size 7
print_hello:
    push rbp
    mov rbp, rsp
    
    ; Allocate 64 bytes:
    ; 32 bytes: shadow space [rsp+0]
    ;  8 bytes: 5th arg (lpOverlapped) [rsp+32]
    ;  8 bytes: bytes_written var [rsp+40]
    ;  'print_hello_var_size' bytes: our string [rsp+48]
    ;  (9 bytes padding)
    sub rsp, 64

%ifdef __Linux
    ; Linux code 
    mov BYTE [rsp + 0], 'h'
    mov BYTE [rsp + 1], 'e'
    mov BYTE [rsp + 2], 'l'
    mov BYTE [rsp + 3], 'l'
    mov BYTE [rsp + 4], 'o'
    mov BYTE [rsp + 5], 0 
    mov BYTE [rsp + 6], 10

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    lea rsi, [rsp]
    mov rdx, print_hello_var_size
    syscall

    add rsp, 64 ; deallocate stack

%elifdef __Darwin
    ; macOS code 
    mov BYTE [rsp + 0], 'h'
    mov BYTE [rsp + 1], 'e'
    mov BYTE [rsp + 2], 'l'
    mov BYTE [rsp + 3], 'l'
    mov BYTE [rsp + 4], 'o'
    mov BYTE [rsp + 5], 0 
    mov BYTE [rsp + 6], 10

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    lea rsi, [rsp]
    mov rdx, print_hello_var_size
    syscall

    add rsp, 64 ; deallocate stack

%else ; Windows
    ; 1. place string in new location
    mov BYTE [rsp + 48 + 0], 'h'
    mov BYTE [rsp + 48 + 1], 'e'
    mov BYTE [rsp + 48 + 2], 'l'
    mov BYTE [rsp + 48 + 3], 'l'
    mov BYTE [rsp + 48 + 4], 'o'
    mov BYTE [rsp + 48 + 5], 0 
    mov BYTE [rsp + 48 + 6], 10
    ; 2. gett STDOUT handle
    ; rsp is aligned, so this call is safe
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    ; rax now holds the handle
    ; 3. Call WriteFile
    mov rcx, rax                     ; 1st arg: hFile (handle from GetStdHandle)
    lea rdx, [rsp + 48]              ; 2nd arg: lpBuffer (our string at rsp+48)
    mov r8, print_hello_var_size     ; 3rd arg: nNumberOfBytesToWrite
    lea r9, [rsp + 40]               ; 4th arg: *lpNumberOfBytesWritten (our var at rsp+40)
    mov QWORD [rsp + 32], 0          ; 5th arg: lpOverlapped (NULL at rsp+32)
    ; rsp is still aligned, so this call is safe ??? maybe anyway
    call WriteFile
    add rsp, 64 ; deallocate all 64 bytes

%endif

    ; Common exit for all platforms
    pop rbp
    ret

 section .text
 global _start
 global _main

 _start:
    call print_hello
%ifdef __Linux
    mov rax, SYSCALL_EXIT
    mov rdi, 0
    syscall
%elifdef __Darwin
    mov rax, SYSCALL_EXIT
    mov rdi, 0
    syscall
%else ; Windows
    ; allocate 64 bytes
    ; I don't know man, windows bs ???
    sub rsp, 64
    call print_hello
    ; 'ExitProcess' will start with rsp at ...0 (aligned).
    mov rcx, 0 ; 1st args: ExitCode
    call ExitProcess
%endif

_main: ; This label is not needed if _start is the entry point
    call _start
    ret