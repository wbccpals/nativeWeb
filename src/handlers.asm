worker_start:
    ; Stack layout:
    ; [rsp]        = connfd
    ; [rsp+8]      = filefd
    ; [rsp+16]     = file_len
    ; [rsp+32]     = request_buffer (2048)
    ; [rsp+2080]   = file_buffer (4096)
    sub rsp, 8192

recall:
    accept [sockfd], 0, 0
    cmp rax, 0
    jl recall
    mov qword[rsp], rax ; connfd

    write 1, served, served_l

    ; Read request
    lea rsi, [rsp+32]
    read [rsp], rsi, 2048

    ; Check API route
    mov rcx, api_route_len
    lea rsi, [rsp+32]
    mov rdi, api_route
    repe cmpsb
    je serve_api

serve_file:
    open filename, O_RDONLY, 0
    cmp rax, 0
    jl error
    mov [rsp+8], rax ; filefd

    lea rsi, [rsp+2080]
    read [rsp+8], rsi, 4096
    mov [rsp+16], rax ; len

    close [rsp+8]

    write [rsp], header, header_l
    
    lea rsi, [rsp+2080]
    mov rdx, [rsp+16]        ; file length
    write [rsp], rsi, rdx 
    
    jmp finish_request

serve_api:
    write [rsp], json_header, json_header_l
    write [rsp], json_body, json_body_l

finish_request:
    jmp close_well

init_error:
    write 1, error_msg, error_msg_l
    exit 1

error:
    write 1, error_msg, error_msg_l
    jmp close_well

close_well:
    close [rsp]
    jmp recall
