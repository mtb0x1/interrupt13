%ifdef __Linux
    %define SYSCALL_EXIT 60
    %define SYSCALL_WRITE 1
    %define STDOUT 1 ; File descriptor 1 is stdout.
%elifdef __Darwin
    %define SYSCALL_EXIT 0x2000001
    %define SYSCALL_WRITE 0x2000004
    %define STDOUT 1 ; File descriptor 1 is stdout.
%endif

[bits 64]

%define print_hello_var_size 7
print_hello:
    push rbp
    mov rbp, rsp
    
    ; allocate 64 bytes
    ; cause why not, also stack must be 16 byte aligned
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
%endif

_main: ; This label is not needed if _start is the entry point
%ifdef __Linux
    call _start
    ret
%elifdef __Darwin
    call _start
    ret
%endif