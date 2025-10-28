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

%define hello_world_size 13
print_hello_world:
    push rbp
    mov rbp, rsp
    
    ; allocate 64 bytes
    ; cause why not, also stack must be 16 byte aligned
    sub rsp, 64

    ; "Hello World!" string
    mov BYTE [rsp + 0], 'H'
    mov BYTE [rsp + 1], 'e'
    mov BYTE [rsp + 2], 'l'
    mov BYTE [rsp + 3], 'l'
    mov BYTE [rsp + 4], 'o'
    mov BYTE [rsp + 5], ' '
    mov BYTE [rsp + 6], 'W'
    mov BYTE [rsp + 7], 'o'
    mov BYTE [rsp + 8], 'r'
    mov BYTE [rsp + 9], 'l'
    mov BYTE [rsp + 10], 'd'
    mov BYTE [rsp + 11], '!'
    mov BYTE [rsp + 12], 10

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    lea rsi, [rsp]
    mov rdx, hello_world_size
    syscall

    add rsp, 64 ; deallocate stack

    ; Common exit for all platforms
    pop rbp
    ret

section .text
global _start
global _main

_start:
    call print_hello_world
    mov rax, SYSCALL_EXIT
    mov rdi, 0
    syscall

_main: ; This label is not needed if _start is the entry point
    call _start
    ret
