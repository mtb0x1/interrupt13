%ifdef __Linux
    %define SYSCALL_EXIT 60
    %define SYSCALL_WRITE 1
%elifdef __Darwin
    %define SYSCALL_EXIT 0x2000001
    %define SYSCALL_WRITE 0x2000004
%endif

%define STDOUT 1 ; File descriptor 1 is stdout.

[bits 64]

section .data
hello_msg db "Hello ", 0
excl_msg db "!", 10, 0
no_arg_msg db "You need to provide a name!", 10, 0

section .text
global _start
global _main

_start:
    pop rcx         ; argc
    cmp rcx, 2
    jl no_arg

    pop rsi         ; argv[0]
    pop rsi         ; argv[1], now rsi point to arg string 
     mov rbx, rsi   ; save arg

     ; write  "Hello "
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rdx, 6
    mov rsi, hello_msg
    syscall

    ; write argument
    mov rdx, 0
    mov rdi, rbx
count_len:
    cmp byte [rdi + rdx], 0
    je done_count
    inc rdx
    jmp count_len
done_count:
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rsi, rbx
    syscall

    ; Write "!\n"
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rsi, excl_msg
    mov rdx, 2
    syscall

    jmp exit_normal

no_arg:
    ; Write error message
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rsi, no_arg_msg
    mov rdx, 28
    syscall

    ; Exit with code 1
    mov rax, SYSCALL_EXIT
    mov rdi, 1
    syscall

exit_normal:
    ; Exit with code 0
    mov rax, SYSCALL_EXIT
    xor rdi, rdi
    syscall

_main: ; This label is not needed if _start is the entry point
    call _start
    ret
