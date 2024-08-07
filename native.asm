format ELF64 executable
STD_out equ 10
SYS_exit equ 60
segment readable writeable
 start db "setting up webNative",STD_out
 start_l = $ - start
segment readable executable
;; Agenda Create a tcp socket
entry main

main:
    mov rax , 1
    mov rdi , 1
    mov rsi , start
    mov rdx, start_l
    syscall
    jmp exit
exit :
    mov rax , SYS_exit
    mov rdi, 0
    syscall
