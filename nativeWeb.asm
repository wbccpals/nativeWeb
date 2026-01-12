format ELF64 executable

include 'src/constants.asm'
include 'src/macros.asm'
include 'src/handlers.asm'

segment readable writeable

struc strucbuilder {
    .sin_family dw 0
    .sin_port   dw 0
    .sin_addr   dd 0
    .sin_zero   dq 0
}

servaddr        strucbuilder
servaddr_len    = $ - servaddr.sin_family
sockfd          dq -1
reuseaddr       dd 1

start           db "setting up webNative", 10
start_l         = $ - start
start_socket    db "INFO: init socket", 10
start_socket_l  = $ - start_socket
error_msg       db "INFO: Error!", 10
error_msg_l     = $ - error_msg
init_bind       db "INFO: Init bind", 10
init_bind_l     = $ - init_bind
listen_msg      db "LISTEN : listening on port 0x22b8", 10
listen_msg_l    = $ - listen_msg
served          db "SERVED : Complete!", 10
served_l        = $ - served

header          db "HTTP/1.1 200 OK", 13, 10
                db "Content-Type: text/html", 13, 10
                db "Connection: close", 13, 10
                db 13, 10
header_l        = $ - header

json_header     db "HTTP/1.1 200 OK", 13, 10
                db "Content-Type: application/json", 13, 10
                db "Connection: close", 13, 10
                db 13, 10
json_header_l   = $ - json_header
 
json_body       db '{"status": "ok", "message": "hello from assembly"}', 10
json_body_l     = $ - json_body

filename        db "file/demo.html", 0
api_route       db "GET /api/health"
api_route_len   = $ - api_route


segment readable executable
entry main

main:
    write 1, start, start_l
    write 1, start_socket, start_socket_l

    ; Create socket
    socket 2, 1, 0         ; AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl init_error
    mov qword [sockfd], rax

    ; Set SO_REUSEADDR
    setsockopt [sockfd], SOL_SOCKET, SO_REUSEADDR, reuseaddr, 4
    
    ; Setup address struct
    mov word  [servaddr.sin_family], 2
    mov word  [servaddr.sin_port], 47138
    mov dword [servaddr.sin_addr], 0

    write 1, init_bind, init_bind_l

    ; Bind
    bind [sockfd], servaddr.sin_family, servaddr_len
    cmp rax, 0
    jl init_error

    ; Listen
    listen [sockfd], 99
    cmp rax, 0
    jl init_error

    write 1, listen_msg, listen_msg_l

    ; Spawn worker threads
    mov rcx, 4

spawn_loop:
    push rcx
    
    ; Allocate stack for thread
    mmap 0, STACK_SIZE, PROT_READ + PROT_WRITE, MAP_PRIVATE + MAP_ANONYMOUS, -1, 0
    
    lea rsi, [rax + STACK_SIZE] ; stack top for child
    
    ; Clone thread
    mov rax, SYS_clone
    mov rdi, CLONE_VM + CLONE_FS + CLONE_FILES + CLONE_SIGHAND + CLONE_THREAD
    syscall
    
    cmp rax, 0
    je worker_start
    
    pop rcx
    dec rcx
    jnz spawn_loop

    ; Main thread becomes a worker too
    jmp worker_start

