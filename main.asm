; *****************************************************************
; Simple Assembly Program to Print Word and Its Length
; Usage: ./main -w <word>
; Prints: <word> <length>
; *****************************************************************

section .data
TRUE equ 1
FALSE equ 0
NULL equ 0
LF equ 10
SPACE equ 32
NEWLINE equ 10

SYS_read    equ 0
SYS_write   equ 1
SYS_open    equ 2
SYS_close   equ 3
SYS_exit    equ 60

STDIN       equ 0
STDOUT      equ 1
STDERR      equ 2

; Error message for invalid args
invalid_args db "Usage: ./main -w <word>", NEWLINE, NULL

; Space for printing between word and length
space_char db SPACE, NULL

; Newline after output
newline db NEWLINE, NULL

section .bss
; Buffer for converting number to string (up to 20 digits + null)
num_buffer resb 21

section .text

global _start

; -----
; Entry point: _start (argc/argv on stack)
_start:
    ; Load argc/argv from stack (before any pushes!)
    mov rdi, [rsp]         ; argc
    lea rsi, [rsp + 8]     ; argv (points to argv[0])

    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    ; Check argc == 3 (program, -w, word)
    cmp rdi, 3
    jne print_usage

    ; Check argv[1] == "-w"
    mov rbx, [rsi + 8]  ; argv[1]
    cmp byte [rbx], '-'
    jne print_usage
    cmp byte [rbx + 1], 'w'
    jne print_usage
    cmp byte [rbx + 2], NULL
    jne print_usage

    ; Get word pointer: argv[2]
    mov r12, [rsi + 16]  ; r12 = word ptr

    ; Compute length
    mov rdi, r12
    call getLength
    mov r13, rax         ; r13 = length

    ; Print the word
    mov rdi, r12
    call printString

    ; Print space
    mov rdi, space_char
    call printString

    ; Convert length to string and print
    mov rdi, r13         ; rdi = number to convert
    mov rsi, num_buffer  ; rsi = buffer
    call intToString
    mov rdi, rsi         ; rdi = buffer with string
    call printString

    ; Print newline
    mov rdi, newline
    call printString

    ; Exit success
    pop r13
    pop r12
    pop rbx
    pop rbp
    mov rax, SYS_exit
    mov rdi, 0
    syscall

print_usage:
    pop r13
    pop r12
    pop rbx
    pop rbp
    mov rdi, invalid_args
    call printString
    mov rax, SYS_exit
    mov rdi, 1
    syscall

; ******************************************************************
; Get length of null-terminated string in rdi
; Returns length in rax
; ******************************************************************
getLength:
    mov rax, 0
str_len_loop:
    cmp byte [rdi + rax], NULL
    je str_len_done
    inc rax
    jmp str_len_loop
str_len_done:
    ret

; ******************************************************************
; Print null-terminated string in rdi to stdout
; ******************************************************************
printString:
    push rbp
    mov rbp, rsp
    push rbx
    push rdx
    push rsi
    push rdi

    ; Count length
    mov rbx, rdi         ; rbx = string ptr
    mov rdx, 0
count_loop:
    cmp byte [rbx + rdx], NULL
    je count_done
    inc rdx
    jmp count_loop
count_done:
    cmp rdx, 0
    je print_done

    ; Syscall write
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, rbx         ; original string ptr
    syscall

print_done:
    pop rdi
    pop rsi
    pop rdx
    pop rbx
    pop rbp
    ret

; ******************************************************************
; Convert unsigned int in rdi to decimal string in buffer rsi
; (simple, assumes < 2^64, no leading zeros except for 0)
; ******************************************************************
intToString:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rbx, rsi         ; rbx = buffer
    mov rcx, 0           ; digit count

    ; Handle 0
    cmp rdi, 0
    jne convert_loop
    mov byte [rbx], '0'
    inc rcx
    jmp reverse_digits

convert_loop:
    mov rdx, 0           ; clear rdx for div
    mov rax, rdi         ; rax = number
    mov r8, 10
    div r8               ; rax / 10, remainder in rdx
    mov rdi, rax         ; update number = quotient
    add dl, '0'          ; dl = '0' + digit
    mov [rbx + rcx], dl  ; store digit (reversed)
    inc rcx
    cmp rdi, 0
    jne convert_loop

reverse_digits:
    mov r9, 0               ; left = 0
    mov r10, rcx
    dec r10                 ; right = len-1
rev_loop:
    cmp r9, r10
    jge add_null
    mov al, [rbx + r9]
    mov bl, [rbx + r10]
    mov [rbx + r9], bl
    mov [rbx + r10], al
    inc r9
    dec r10
    jmp rev_loop

add_null:
    mov byte [rbx + rcx], NULL  ; null terminate

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
