macro write fd, buf, count {
    mov rax, SYS_write
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

macro read fd, buf, count {
    mov rax, SYS_read
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

macro open filename, flags, mode {
    mov rax, SYS_open
    mov rdi, filename
    mov rsi, flags
    mov rdx, mode
    syscall
}

macro close fd {
    mov rax, SYS_close
    mov rdi, fd
    syscall
}

macro exit code {
    mov rax, SYS_exit
    mov rdi, code
    syscall
}

macro socket domain, type, protocol {
    mov rax, SYS_socket
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    syscall
}

macro bind sockfd, addr, addrlen {
    mov rax, SYS_bind
    mov rdi, sockfd
    mov rsi, addr
    mov rdx, addrlen
    syscall
}

macro listen sockfd, backlog {
    mov rax, SYS_listen
    mov rdi, sockfd
    mov rsi, backlog
    syscall
}

macro accept sockfd, addr, addrlen {
    mov rax, SYS_accept
    mov rdi, sockfd
    mov rsi, addr
    mov rdx, addrlen
    syscall
}

macro setsockopt sockfd, level, optname, optval, optlen {
    mov rax, SYS_setsockopt
    mov rdi, sockfd
    mov rsi, level
    mov rdx, optname
    mov r10, optval
    mov r8, optlen
    syscall
}

macro mmap addr, length, prot, flags, fd, offset {
    mov rax, SYS_mmap
    mov rdi, addr
    mov rsi, length
    mov rdx, prot
    mov r10, flags
    mov r8, fd
    mov r9, offset
    syscall
}
