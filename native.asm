format ELF64 executable
STD_out equ 1
STD_err equ 2
SYS_exit equ 60
SYS_socket equ 41

segment readable writeable
 start db "setting up webNative",10
 start_l = $ - start
 start_socket db "init socket",10
 start_scoket_l = $ - start_socket
 error_msg db "Error!",10
 error_msg_l = $ - error_msg
 init_socket db "Init socket",10
 init_socket_l = $ - init_socket
segment readable executable
;; Agenda Create a tcp socket
entry main

main:
  ;;Start message
    mov rax , STD_out
    mov rdi , 1
    mov rsi , start
    mov rdx, start_l
    syscall
  ;;init scoket message
    mov rax , STD_out
    mov rdi , 1
    mov rsi , init_socket
    mov rdx, init_socket_l
    syscall
   ;; create socket  -- socket(domain,type,protocol)
    mov rax , SYS_socket
    mov rdi , 2 ;; AF_INET
    mov rsi, 1  ;; SOCK_STREAM
    mov rdx,0    ;; Since stream is tcp
    syscall
    cmp rax , 0
    jl error
   ;; Bind socket --
    jmp exit
exit :
    mov rax , SYS_exit
    mov rdi, 0
    syscall
exit_err :
    mov rax , SYS_exit
    mov rdi, 1
    syscall
error :
    mov rax,STD_err
    mov rdi ,1
    mov rsi, error_msg
    mov rdx , error_msg_l
    syscall
    jmp exit_err
