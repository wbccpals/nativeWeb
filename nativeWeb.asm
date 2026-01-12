format ELF64 executable

SYS_read equ 0
SYS_write equ 1
SYS_open equ 2
SYS_close equ 3
SYS_mmap equ 9
SYS_munmap equ 11
SYS_clone equ 56
SYS_exit equ 60
SYS_socket equ 41
SYS_accept equ 43
SYS_bind equ 49
SYS_listen equ 50
SYS_setsockopt equ 54

O_RDONLY equ 0
PROT_READ equ 1
PROT_WRITE equ 2

SOL_SOCKET equ 1
SO_REUSEADDR equ 2

MAP_PRIVATE equ 2
MAP_ANONYMOUS equ 32
CLONE_VM equ 0x00000100
CLONE_FS equ 0x00000200
CLONE_FILES equ 0x00000400
CLONE_SIGHAND equ 0x00000800
CLONE_THREAD equ 0x00010000

STACK_SIZE equ 1024 * 1024

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
   sockfd dq -1
   reuseaddr dd 1

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

segment readable executable
entry main

main:

    ;Start message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , start
    mov rdx, start_l
    syscall

    ;init scoket message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , init_socket
    mov rdx, init_socket_l
    syscall

    ; create socket  -- socket(domain,type,protocol)
    mov rax , SYS_socket
    mov rdi , 2 ; AF_INET
    mov rsi, 1  ; SOCK_STREAM
    mov rdx,0   ; tcp
    syscall
    cmp rax , 0
    jl init_error
    mov qword [sockfd],rax

    ;; Set SO_REUSEADDR
    mov rax, SYS_setsockopt
    mov rdi, [sockfd]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    mov r10, reuseaddr
    mov r8, 4 ; sizeof(int)
    syscall

    ;; Bind socket -- sockaddr_in sin_f16,sin_p16,sin_a32,sin_z[8]64
    mov word  [servaddr.sin_family], 2  ; AF_INET
    mov word  [servaddr.sin_port],47138 ;0xb822 (0x22b8 ||8888) altered Msb;;
    mov dword [servaddr.sin_addr], 0    ;iaddr any

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
    jl init_error

    ;;listen to the socket

    mov rax, SYS_listen
    mov rdi, [sockfd]
    mov rsi, 99 ;; max connections
    syscall
    cmp rax ,0
    jl init_error

    ;;listen message
    mov rax , SYS_write
    mov rdi , 1
    mov rsi , listen
    mov rdx, listen_l
    syscall

    ;; Spawn worker threads
    mov rcx, 4  ; Number of additional threads

spawn_loop:
    push rcx

    ; mmap stack
    mov rax, SYS_mmap
    mov rdi, 0
    mov rsi, STACK_SIZE
    mov rdx, PROT_READ + PROT_WRITE
    mov r10, MAP_PRIVATE + MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    syscall

    ; Calculate top of stack
    lea rsi, [rax + STACK_SIZE]

    ; Clone thread
    ; Flags: CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD
    mov rax, SYS_clone
    mov rdi, CLONE_VM + CLONE_FS + CLONE_FILES + CLONE_SIGHAND + CLONE_THREAD
    ; rsi already has child stack
    syscall

    cmp rax, 0
    je worker_start

    pop rcx
    dec rcx
    jnz spawn_loop

    ; Main thread also becomes a worker
    jmp worker_start

worker_start:
    ; Allocate stack buffers
    ; [rsp] = connfd (8 bytes)
    ; [rsp+8] = filefd (8 bytes)
    ; [rsp+16] = file_len (8 bytes)
    ; [rsp+32] = request_buffer (2048 bytes)
    ; [rsp+2080] = file_buffer (4096 bytes)
    sub rsp, 8192

recall:

    ;;Accept connection
    mov rax, SYS_accept
    mov rdi , [sockfd]
    mov rsi, 0 
    mov rdx , 0
    syscall
    cmp rax ,0
    jl recall ; If accept fails
    mov qword[rsp], rax ; connfd

    mov rax , SYS_write
    mov rdi , 1
    mov rsi , served
    mov rdx, served_l
    syscall

    ;; READ THE REQUEST
    mov rax, SYS_read
    mov rdi, [rsp] ; connfd
    lea rsi, [rsp+32] ; request_buffer
    mov rdx, 2048
    syscall

    ;; Check for API route
    ;; Compare request_buffer with api_route
    mov rcx, api_route_len
    lea rsi, [rsp+32] ; request_buffer
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
    mov [rsp+8], rax ; filefd

    ;; Read the file
    mov rax, SYS_read
    mov rdi, [rsp+8] ; filefd
    lea rsi, [rsp+2080] ; file_buffer
    mov rdx, 4096
    syscall
    mov [rsp+16], rax ; file_len

    ;; Close the file
    mov rax, SYS_close
    mov rdi, [rsp+8] ; filefd
    syscall

    ;; Write header to connfd
    mov rax, SYS_write
    mov rdi, [rsp] ; connfd
    mov rsi, header
    mov rdx, header_l
    syscall

    ;; Write file content to connfd
    mov rax, SYS_write
    mov rdi, [rsp] ; connfd
    lea rsi, [rsp+2080] ; file_buffer
    mov rdx, [rsp+16] ; file_len
    syscall

    jmp finish_request

serve_api:
    ;; Write JSON Header
    mov rax, SYS_write
    mov rdi, [rsp] ; connfd
    mov rsi, json_header
    mov rdx, json_header_l
    syscall

    ;; Write JSON Body
    mov rax, SYS_write
    mov rdi, [rsp] ; connfd
    mov rsi, json_body
    mov rdx, json_body_l
    syscall

finish_request:
    cmp rax ,0
    jl error
    jmp close_well

exit_well :
    mov rax , SYS_close
    mov rdi, [rsp] ; connfd
    syscall
    mov rax , SYS_exit
    mov rdi, 0
    syscall

exit :
    mov rax , SYS_exit
    mov rdi, 1
    syscall

init_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_msg_l
    syscall
    jmp exit

error :
    mov rax,2 ;
    mov rdi ,1
    mov rsi, error_msg
    mov rdx , error_msg_l
    syscall
    jmp close_well

close :
    ; mov rax , SYS_close
    ; mov rdi , [sockfd]

    mov rax , SYS_close
    mov rdi, [rsp] ; connfd

    syscall
    jmp exit ;

close_well:
    ;; We only close connfd here so we can loop back to accept
    mov rax , SYS_close
    mov rdi, [rsp] ; connfd
    syscall

    jmp recall   ;restart after serving req
