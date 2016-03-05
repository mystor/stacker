;; -*- nasm -*-

%define SYS_WRITE 1
%define SYS_READ 0
%define SYS_EXIT 60
%define STDIN 0
%define STDOUT 1
%define STDERR 2

        section .bss
strbuf: resb 1024
cmdbuf: resb 1024
cmdidx: resq 1

section .rodata
code_add:
        pop rax
        add [rsp], rax
.len: equ $ - code_add
code_sub:
        pop rax
        sub [rsp], rax
.len: equ $ - code_sub
code_mul:
        pop rax
        pop rdx
        imul rcx, rdx
        push rax
.len: equ $ - code_mul
code_div:
        xor rdx, rdx
        pop rcx
        pop rax
        idiv rcx
        push rax
.len: equ $ - code_div
code_mod:
        xor rdx, rdx
        pop rcx
        pop rax
        idiv rcx
        push rdx
.len: equ $ - code_mod
code_cpy:
        push QWORD [rsp]
.len: equ $ - code_cpy
code_swp:
        pop rax
        pop rbx
        push rax
        push rbx
.len: equ $ - code_swp

code_exit:
        pop r8                  ; r8 is value we want to print
        mov r9, 1
        sub rsp, 1              ; Add a newline
        mov BYTE [rsp], 10
.loop:
        xor rdx, rdx
        mov rax, r8
        mov rcx, 10             ; Divide the input number by 10
        div rcx
        mov r8, rax             ; Save the new value back into r8
        add rdx, '0'            ; Offset the remainder by the char code for '0'
        sub rsp, 1
        mov [rsp], dl
        inc r9
        cmp r8, 0
        jne .loop
.after:
        ; Write out the letter
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, rsp
        mov rdx, r9
        syscall
        ; Exit the program
        mov rax, SYS_EXIT
        mov rdi, 0
        syscall
.len: equ $ - code_exit

        section .data
code_push: db 0x68              ; byte code for push 32-bit intermediate
.val: times 4 db 0              ; 32-bit intermediate
.len: equ $ - code_push

ELF_prelude:
.ei_mag: db 0x7F, "ELF"         ; Magic number
.ei_class: db 2                 ; pointer size (32-bit = 1, 64-bit = 2)
.ei_data: db 1                  ; 1 = little endian, 2 = big endian
.ei_version: db 1               ; version 1 of ELF
.ei_osabi: db 0x03              ; Operating System ABI (linux = 0x03)
.ei_abiversion: db 0            ; ignored by linux
.ei_pad: times 7 db 0           ; padding
.e_type: dw 2                   ; 1 = relocatable, 2 = executable, 3 = shared, 4 = core
.e_machine: dw 0x3E             ; ISA (x86 = 0x03, x86-64 = 0x3E)
.e_version: dd 1                ; version 1 of ELF
.e_entry: dq 0x400078           ; Memory address of entry point
.e_phoff: dq 0x40               ; Program header offset
.e_shoff: dq 0                  ; Section header offset (absent from executable)
.e_flags: dd 0                  ; Flags
.e_ehsize: dw 0x40              ; Size of this header
.e_phentsize: dw 0x38           ; Size of a program header table entry
.e_phnum: dw 1                  ; Number of entries in program header table
.e_shentsize: dw 0x40           ; Size of a section header entry
.e_shnum: dw 0                  ; Number of entries in the section header
.e_shstrndx: dw 0               ; Section header table for names index

ELF_text:
.p_type: dd 1
.p_flags: dd 0x5
.p_offset: dq 0x78              ; Segment file offset
.p_vaddr: dq 0x400078           ; Segment virtual address
.p_paddr: dq 0x400078           ; Segment physical address (unused)
.p_filesz: dq 0xDEADBEEF        ; Segment size in file
.p_memsz: dq 0xDEADBEEF         ; Segment size in memory
.p_align: dq 0x200000           ; Segment alignment, file & memory

ELF_prelude_len: equ $ - ELF_prelude

        section .text
global _start
_start:
.loop:
        call readcmd
        cmp rax, 0
        jne .loop
        call writeend
        call writecode
        call exit

writeend:
        mov rsi, code_exit
        mov rcx, code_exit.len
        call cmdappend
        ret

writecode:
        ; first we have to write the elf prelude
        mov rcx, [cmdidx]       ; bytes of code
        mov [ELF_text.p_filesz], rcx
        mov [ELF_text.p_memsz], rcx
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, ELF_prelude
        mov rdx, ELF_prelude_len
        syscall
        ; Then we write out the main code
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, cmdbuf
        mov rdx, [cmdidx]
        syscall
        ret

;; rcx = length
;; rsi = source
cmdappend:
        mov rax, [cmdidx]
        add [cmdidx], rcx
        lea rdi, [cmdbuf+rax]
        rep movsb               ; Copy the bytes over!
        ret

readcmd:
        call readtoken
        cmp rax, 0              ; 0 bytes means we've reached eof, so just exit
        jne .tokenread
        ret
.tokenread:
        ; Either we see a symbol (+, -, *, /) and want to handle that
        ; or we see push, or we should error
        cmp rax, 1              ; symbol
        je .symbol
        cmp rax, 4              ; 'push', 'swap', 'copy'
        je .word
        ; Report an error!
        jmp unexpectedtoken
.symbol:
        ; All operators happen to be 1 character long - 1 byte
        cmp BYTE [strbuf], '+'
        je .add
        cmp BYTE [strbuf], '-'
        je .sub
        cmp BYTE [strbuf], '*'
        je .mul
        cmp BYTE [strbuf], '/'
        je .div
        cmp BYTE [strbuf], '%'
        je .mod
        jmp unexpectedtoken
.word:
        ; all symbols happen to be exactly 4 letters long - 1 dword
        cmp DWORD [strbuf], 'push' ; Check buffer contains push
        je .push
        cmp DWORD [strbuf], 'swap' ; Check buffer contains push
        je .swap
        cmp DWORD [strbuf], 'copy' ; Check buffer contains push
        je .copy
        jmp unexpectedtoken
.add:
        mov rsi, code_add
        mov rcx, code_add.len
        jmp .writeret
.sub:
        mov rsi, code_sub
        mov rcx, code_sub.len
        jmp .writeret
.mul:
        mov rsi, code_mul
        mov rcx, code_mul.len
        jmp .writeret
.div:
        mov rsi, code_div
        mov rcx, code_div.len
        jmp .writeret
.mod:
        mov rsi, code_mod
        mov rcx, code_mod.len
        jmp .writeret
.copy:
        mov rsi, code_cpy
        mov rcx, code_cpy.len
        jmp .writeret
.swap:
        mov rsi, code_swp
        mov rcx, code_swp.len
        jmp .writeret
.push:
        call readtoken
        call parseinttoken
        mov [code_push.val], eax
        mov rsi, code_push
        mov rcx, code_push.len
        jmp .writeret
.writeret:
        ; copy bytes into the result buffer
        call cmdappend
        mov rax, 1              ; rax = 1 means something was written
        ret

parseinttoken:
        ; rax is length of bufferj
        xor r8, r8              ; r8 is curent buffer index
        xor r9, r9              ; r9 = 1 means negate
        xor rcx, rcx            ; rcx = current number
        xor rbx, rbx            ; rbx = scratch buffer for character
        cmp BYTE [strbuf], '-'  ; Check for negation
        jne .loop
        inc r8                  ; Skip the - sign
        mov r9, 1              ; mark for negation
.loop:
        cmp r8, rax
        jae .done
        mov bl, [strbuf]
        cmp bl, '9'
        ja unexpectedtoken
        sub bl, '0'
        jb unexpectedtoken
        add rcx, rbx
        inc r8
        jmp .loop
.done:
        cmp r9, 1
        jne .return
        neg rcx
.return:
        mov rax, rcx
        ret

;; -1 signals eof
;; Preserves r8-r15
readchr:
        push 0
        mov rax, SYS_READ
        mov rdi, STDIN
        mov rsi, rsp
        mov rdx, 1
        syscall
        cmp rax, 1
        jne .eof
        pop rax
        ret
.eof:
        pop rax
        mov rax, -1
        ret

;; Reads in characters until reading a seperator
;; Returns length in rax
;; string is stored in strbuf
;; XXX: Make this discard leading seps if there are multiple
readtoken:
        xor r9, r9              ; zero out our counter
.loop:
        call readchr
        cmp rax, ' '
        je .seperator
        cmp rax, 10             ; NL
        je .seperator
        cmp rax, -1             ; EOF
        je .done
        mov [strbuf+r9], al
        inc r9
        cmp r9, 1024
        ja .done
        jmp .loop
.seperator:
        ; Continue if we haven't read any bytes yet to skip leading seps
        cmp r9, 0
        je .loop
.done:
        mov rax, r9
        ret


        section .data
unexpected1: db 'unexpected token '
.len: equ $ - unexpected1

        section .text
unexpectedtoken:
        push rax                ; save the length of the token
        mov rax, SYS_WRITE
        mov rdi, STDERR
        mov rsi, unexpected1
        mov rdx, unexpected1.len
        syscall
        mov rax, SYS_WRITE
        mov rdi, STDERR
        mov rsi, strbuf
        pop rdx
        syscall
        mov rax, SYS_EXIT
        mov rdi, 0
        syscall

exit:
        mov rax, SYS_EXIT
        mov rdi, 0
        syscall

;printnewline:
;        push 10                 ; space
;        mov rax, SYS_WRITE
;        mov rdi, 2
;        mov rsi, rsp
;        mov rdx, 1
;        syscall
;        pop rax
;        ret
;
;;; Argument in rax
;printnum:
;        mov r8, rax
;        mov r9, 0
;.loop:
;        xor rdx, rdx
;        mov rax, r8
;        mov rcx, 10             ; Divide the input number by 10
;        div rcx
;        mov r8, rax             ; Save the new value back into r8
;        add rdx, '0'            ; Offset the remainder by '0'
;        sub rsp, 1
;        mov [rsp], dl
;        inc r9
;        cmp r8, 0
;        jne .loop
;.after:
;        ; Write out the letter
;        mov rax, SYS_WRITE
;        mov rdi, 2
;        mov rsi, rsp
;        mov rdx, r9
;        syscall
;        add rsp, r9             ; Free the stack space
;        ret
;.len: equ $ - printnum
