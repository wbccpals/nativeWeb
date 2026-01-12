; Syscall Numbers
SYS_read       equ 0
SYS_write      equ 1
SYS_open       equ 2
SYS_close      equ 3
SYS_mmap       equ 9
SYS_munmap     equ 11
SYS_clone      equ 56
SYS_exit       equ 60
SYS_socket     equ 41
SYS_accept     equ 43
SYS_bind       equ 49
SYS_listen     equ 50
SYS_setsockopt equ 54

; Constants
O_RDONLY       equ 0
PROT_READ      equ 1
PROT_WRITE     equ 2
SOL_SOCKET     equ 1
SO_REUSEADDR   equ 2
MAP_PRIVATE    equ 2
MAP_ANONYMOUS  equ 32

; Clone Flags
CLONE_VM       equ 0x00000100
CLONE_FS       equ 0x00000200
CLONE_FILES    equ 0x00000400
CLONE_SIGHAND  equ 0x00000800
CLONE_THREAD   equ 0x00010000

STACK_SIZE     equ 1024 * 1024
