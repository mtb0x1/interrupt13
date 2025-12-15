%define SYSCALL_EXIT 60
%define SYSCALL_WRITE 1
%define STDOUT 1 ; File descriptor 1 is stdout.

[bits 64]
default rel ;https://sayansivakumaran.com/posts/2024/4/rip-relative-addressing-in-x86-64/

section .data align=8 ;https://stackoverflow.com/questions/45874323/how-to-set-the-alignment-for-the-data-section
hello_msg db "Hello ", 10, 0
excl_msg db "!", 10, 0
no_arg_msg db "You need to provide a name!", 10, 0

section .text align=16 ;https://stackoverflow.com/questions/45874323/how-to-set-the-alignment-for-the-data-section
global _start
global _main


_start:
    pop rcx         ; argc
    cmp rcx, 2
    jl no_arg

    pop rsi         ; argv[0]
    pop rsi         ; argv[1], now rsi point to arg string 
    mov rbx, rsi   ; save arg

    ; IN-PLACE STRING UNESCAPING
    ; rbx points to the string. We will read from [src_ptr] and write to [dst_ptr].
    ; Since unescaping always shortens or keeps length same, we can do this safely in one pass.
    
    mov rsi, rbx      ; source pointer (reader)
    mov rdi, rbx      ; destination pointer (writer)

.unescape_loop:
    mov al, byte [rsi]
    test al, al
    jz .unescape_done

    cmp al, '\'       ; Check for backslash
    je .handle_escape

    ; Normal character, just copy
    mov byte [rdi], al
    inc rsi
    inc rdi
    jmp .unescape_loop

.handle_escape:
    inc rsi           ; Skip '\'
    mov al, byte [rsi] ; Get next char
    test al, al
    jz .unescape_done  ; String ended with '\', treat as end

    ; Check supported escapes
    cmp al, 'n'
    je .esc_newline
    cmp al, 'r'
    je .esc_return
    cmp al, 't'
    je .esc_tab
    cmp al, '0'
    je .esc_null
    
    ; If not special (or is \\), just copy the character literally
    mov byte [rdi], al
    jmp .next_char

.esc_newline:
    mov byte [rdi], 10
    jmp .next_char
.esc_return:
    mov byte [rdi], 13
    jmp .next_char
.esc_tab:
    mov byte [rdi], 9
    jmp .next_char
.esc_null:
    mov byte [rdi], 0  ; Null terminator detected
    jmp .unescape_done ; Stop processing, we truncated the string here

.next_char:
    inc rsi
    inc rdi
    jmp .unescape_loop

.unescape_done:
    mov byte [rdi], 0 ; Ensure null-termination at new end

    ; Now calculate new length for writing (rdi points to end, rbx is start)
    ; But we loop again to print later or just count
    ; Actually the code below re-counts length starting from rbx, so we are good.

    ; write  "Hello "
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    mov rdx, 6
    lea rsi, [rel hello_msg] 
    syscall

    ; write argument
    mov rdx, 0
    mov rdi, rbx
    mov rsi, rbx   ; rsi must point to buffer for write syscall below (though we recount first)

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
    lea rsi, [rel excl_msg] 
    mov rdx, 2
    syscall

    jmp exit_normal

no_arg:
    ; Write error message
    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT
    lea rsi, [rel no_arg_msg]
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
