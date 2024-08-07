format ELF64 executable
STD_out equ 1
STD_err equ 2
SYS_exit equ 60
SYS_socket equ 41
SYS_bind equ 49
SYS_listen equ 50
SYS_close equ 3

segment readable writeable
 sockfd dq 0
 servaddr.sin_family dw 0
 servaddr.sin_port dw 0
 servaddr.sin_addr dd 0
 servaddr.sin_z dq 0
 sizeof_servaddr = $ - servaddr.sin_family
 INADDR_ANY = 0

 start db "setting up webNative",10
 start_l = $ - start
 start_socket db "INFO: init socket",10
 start_scoket_l = $ - start_socket
 error_msg db "INFO: Error!",10
 error_msg_l = $ - error_msg
 init_socket db "INFO: Init socket",10
 init_socket_l = $ - init_socket
 init_bind db "INFO: Init bind",10
 init_bind_l = $ - init_bind
 OK db "OK",10
 OK_l = $ - OK
 listen db "LISTEN : listening on port 0x22b8",10
 listen_l = $ - listen

segment readable executable
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
    mov qword [sockfd],rax

    ;; Bind socket -- sockaddr_in sin_f16,sin_p16,sin_a32,sin_z[8]64
    mov word  [servaddr.sin_family], 2  ;; AF_INET
    mov word  [servaddr.sin_port],47138 ;;0xb822 (0x22b8 ||8888) altered Msb;;
    mov dword [servaddr.sin_addr], 0

    ;;BIND message
    mov rax , STD_out
    mov rdi , 1
    mov rsi , init_bind
    mov rdx, init_bind_l
    syscall

    ;; call bind syscall bind(sockfd,*addr,addrlen)
    mov rax,  SYS_bind
    mov rdi , [sockfd]
    mov rsi,  servaddr.sin_family
    mov rdx,  sizeof_servaddr
    syscall
    cmp rax , 0
    jl error

    ;;listen to the socket

    mov rax, SYS_listen
    mov rdi, [sockfd]
    mov rsi, 99 ;; max connections
    syscall
    cmp rax ,0
    jl error

    ;;listen message
    mov rax , STD_out
    mov rdi , 1
    mov rsi , listen
    mov rdx, listen_l
    syscall

    jmp exit_well

exit_well :
    mov rax , SYS_exit
    mov rdi, 0
    syscall

exit :
    mov rax , SYS_exit
    mov rdi, 1
    syscall

error :
    mov rax,STD_err
    mov rdi ,1
    mov rsi, error_msg
    mov rdx , error_msg_l
    syscall
    jmp close

close :
    mov rax , SYS_close
    mov rdi , [sockfd]
    jmp exit
