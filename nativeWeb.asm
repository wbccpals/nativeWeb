format ELF64 executable

SYS_read equ 0
SYS_write equ 1
SYS_open equ 2
SYS_close equ 3
STD_err equ 2
SYS_exit equ 60
SYS_socket equ 41
SYS_accept equ 43
SYS_bind equ 49
SYS_listen equ 50

O_RDONLY equ 0

segment readable writeable
struc strucbuilder
{
         .sin_family dw 0
         .sin_port   dw 0
         .sin_addr   dd 0
         .sin_zero   dq 0
}

   servaddr strucbuilder
   servaddr_len = $ - servaddr.sin_family
   respaddr strucbuilder
   respaddr_len dd servaddr_len
   connfd dq -1
   sockfd dq -1
   filefd dq -1
   
   INADDR_ANY = 0


 start db "setting up webNative",10
 start_l = $ - start
 start_socket db "INFO: init socket",10
 start_socket_l = $ - start_socket
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
 served db "SERVED : Complete!",10
 served_l = $ - served


 header db "HTTP/1.1 200 OK",13,10
          db "Content-Type: text/html",13,10
          db "Connection: close",13,10
          db 13,10
 header_l = $ - header

 ; JSON Response
 json_header db "HTTP/1.1 200 OK",13,10
             db "Content-Type: application/json",13,10
             db "Connection: close",13,10
             db 13,10
 json_header_l = $ - json_header
 
 json_body   db '{"status": "ok", "message": "hello from assembly"}', 10
 json_body_l = $ - json_body

 filename db "demo.html", 0
 
 api_route db "GET /api/health"
 api_route_len = $ - api_route

 request_buffer rb 2048

 file_buffer rb 4096
 file_len dq 0

segment readable executable
entry main

main:

    ;;Start message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , start
    mov rdx, start_l
    syscall

    ;;init scoket message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , init_socket
    mov rdx, init_socket_l
    syscall

    ;; create socket  -- socket(domain,type,protocol)
    mov rax , SYS_socket
    mov rdi , 2 ;; AF_INET
    mov rsi, 1  ;; SOCK_STREAM
    mov rdx,0   ;; Since stream is tcp
    syscall
    cmp rax , 0
    jl error
    mov qword [sockfd],rax

    ;; Bind socket -- sockaddr_in sin_f16,sin_p16,sin_a32,sin_z[8]64
    mov word  [servaddr.sin_family], 2  ;; AF_INET
    mov word  [servaddr.sin_port],47138 ;;0xb822 (0x22b8 ||8888) altered Msb;;
    mov dword [servaddr.sin_addr], 0    ;;iaddr any

    ;;BIND message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , init_bind
    mov rdx, init_bind_l
    syscall

    ;; call bind syscall bind(sockfd,*addr,addrlen)
    mov rax,  SYS_bind
    mov rdi , [sockfd]
    mov rsi,  servaddr.sin_family
    mov rdx,  servaddr_len
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
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , listen
    mov rdx, listen_l
    syscall

recall:

    ;;Accept connection
    mov rax, SYS_accept
    mov rdi , [sockfd]
    mov rsi, respaddr.sin_family
    mov rdx , respaddr_len
    syscall
    cmp rax ,0
    jl error
    mov qword[connfd], rax
    
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , served
    mov rdx, served_l
    syscall

    ;; READ THE REQUEST
    mov rax, SYS_read
    mov rdi, [connfd]
    mov rsi, request_buffer
    mov rdx, 2048
    syscall
    
    ;; Check for API route
    ;; Compare request_buffer with api_route
    mov rcx, api_route_len
    mov rsi, request_buffer
    mov rdi, api_route
    repe cmpsb
    je serve_api

serve_file:
    ;; Open the file
    mov rax, SYS_open
    mov rdi, filename
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error
    mov [filefd], rax

    ;; Read the file
    mov rax, SYS_read
    mov rdi, [filefd]
    mov rsi, file_buffer
    mov rdx, 4096
    syscall
    mov [file_len], rax
    
    ;; Close the file
    mov rax, SYS_close
    mov rdi, [filefd]
    syscall

    ;; Write header to connfd
    mov rax, SYS_write
    mov rdi, [connfd]
    mov rsi, header
    mov rdx, header_l
    syscall

    ;; Write file content to connfd
    mov rax, SYS_write
    mov rdi, [connfd]
    mov rsi, file_buffer
    mov rdx, [file_len]
    syscall
    
    jmp finish_request

serve_api:
    ;; Write JSON Header
    mov rax, SYS_write
    mov rdi, [connfd]
    mov rsi, json_header
    mov rdx, json_header_l
    syscall
    
    ;; Write JSON Body
    mov rax, SYS_write
    mov rdi, [connfd]
    mov rsi, json_body
    mov rdx, json_body_l
    syscall
    
finish_request:
    cmp rax ,0
    jl error
    jmp close_well

   ;; Next milestone - Add support for file serving

exit_well :
    mov rax , SYS_close
    mov rdi,[connfd]
    syscall
    mov rax , SYS_close
    mov rdi , [sockfd]
    syscall
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

    mov rax , SYS_close
    mov rdi,[connfd]

    syscall
    jmp exit

close_well:
    ;; We only close connfd here so we can loop back to accept
    mov rax , SYS_close
    mov rdi,[connfd]
    syscall
    
    jmp recall   ;; restart after serving req
