 BITS 64 ; 64 bits.
 CPU X64 ; Target the x86_64 family of CPUs.

 %define SYSCALL_EXIT 60 ; Syscall number for exit.
 %define SYSCALL_WRITE 1 ; Syscall number for write.
 %define STDOUT 1 ; File descriptor 1 is stdout.
 %define AF_UNIX 1 ; Address family: Unix domain sockets.
 %define SOCK_STREAM 1 ; Socket type: Stream socket.
 %define SYSCALL_SOCKET 41 ; Syscall number for socket.

 print_hello:
    %define print_hello_var_size 7 ; Size of the string "hello0\n"
    push rbp ; Save rbp on the stack to be able to restore it at the end of the function.
    mov rbp, rsp ; Set rbp to rsp
    sub rsp, print_hello_var_size ; Reserve 5 bytes of space on the stack.
    mov BYTE [rsp + 0], 'h' ; Set each byte on the stack to a string character.
    mov BYTE [rsp + 1], 'e'
    mov BYTE [rsp + 2], 'l'
    mov BYTE [rsp + 3], 'l'
    mov BYTE [rsp + 4], 'o'
    mov BYTE [rsp + 5], 0 ; Null-terminate the string. ??
    mov BYTE [rsp + 6], 10 ; New line character.

    ; Make the write syscall
    mov rax, SYSCALL_WRITE ; Syscall: write. (1)
    mov rdi, STDOUT ; Write to stdout.
    lea rsi, [rsp] ; Address on the stack of the string.
    mov rdx, print_hello_var_size ; Pass the length of the string
    syscall
    add rsp, print_hello_var_size ; Restore the stack to its original value.
    pop rbp ; Restore rbp
    ret

 section .text
 global _start:
 _start:
    call print_hello ; Call the print_hello function.
    mov rax, SYSCALL_EXIT ; Syscall: exit. (60)
    mov rdi, 0 ; Exit code 0.
    syscall ; Make the syscall.