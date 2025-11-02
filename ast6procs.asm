; *****************************************************************
; Name: John Doe
; NSHE_ID: 0123456789
; Section: 9999
; Assignment: 6
; Description: File IO - C++-ASM connectivity for buffered word reading and counting
; *****************************************************************

section .data
TRUE equ 1
FALSE equ 0
NULL equ 0
LF equ 10
NEWLINE equ 10

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

SPACE_ASCII equ 32

invalidArgumentCount db "You have given an invalid command line argument. Make sure it follows this format:",NEWLINE," ./main -f <fileName> -w <word>", NULL
invalidFArgument db "Your first argument is not -f.", NEWLINE ,NULL
invalidWArgument db "Your second argument is not -w.", NEWLINE, NULL
invalidFile db "You did not open a valid file. Try Again", NEWLINE, NULL
invalidWord db "Your word has exceded the limit of MAXWORDLENGTH", NEWLINE, NULL

BUFFSIZE equ 300000
buffIndex dq 0
buffCurr dq 0
wasEOF db 0

section .bss
buffer resb BUFFSIZE

section .text

; rdi = int argc
; rsi = char* argv[]
; rdx = int MAXWORDLENGTH
; rcx = char[] wordSaved
; r8  = long long& fileDescriptor
global checkParams
checkParams:
    push rbp
    mov rbp, rsp
    push rbx                     ; save rbx, non-volatile register

    ; ---------------------------------------------------------
    ; Save argv in r10 for later use (rsi will be clobbered by syscalls)
    ; ---------------------------------------------------------
    mov r10, rsi                 ; r10 = argv[]

    ; ---------------------------------------------------------
    ; 1. Check argc == 5
    ; Anything else results in an error
    ; ---------------------------------------------------------
    cmp rdi, 5
    jne invalid_arg_count

    ; ---------------------------------------------------------
    ; 2. Check argv[1] == "-f"
    ; argv[1] is at [r10 + 8] (64-bit pointers)
    ; Verify exact string "-f" followed by null terminator
    ; ---------------------------------------------------------
    mov rbx, [r10 + 8]           ; load pointer to argv[1]
    cmp byte [rbx], '-'
    jne invalid_f
    cmp byte [rbx + 1], 'f'
    jne invalid_f
    cmp byte [rbx + 2], NULL
    jne invalid_f

    ; ---------------------------------------------------------
    ; 3. Open the file specified in argv[2]
    ; argv[2] is at [r10 + 16]
    ; Use SYS_open with O_RDONLY flag
    ; Store successful file descriptor in [r8] via reference
    ; If open fails (rax < 0), error
    ; ---------------------------------------------------------
    push rcx                     ; save wordSaved ptr (rcx, clobbered by syscall)
    push rdx                     ; save MAXWORDLENGTH
    mov rbx, [r10 + 16]          ; load pointer to filename (argv[2])
    mov rax, SYS_open
    mov rdi, rbx                 ; arg1: filename
    mov rsi, O_RDONLY            ; arg2: read-only mode
    mov rdx, 0                   ; arg3: mode (unused for read-only)
    syscall
    pop rdx                      ; restore MAXWORDLENGTH
    pop rcx                      ; restore wordSaved ptr
    cmp rax, 0
    jl invalid_file
    mov [r8], rax                ; store file descriptor via reference

    ; ---------------------------------------------------------
    ; 4. Check argv[3] == "-w"
    ; argv[3] is at [r10 + 24]
    ; Verify exact string "-w" followed by null terminator
    ; ---------------------------------------------------------
    mov rbx, [r10 + 24]          ; load pointer to argv[3]
    cmp byte [rbx], '-'
    jne invalid_w
    cmp byte [rbx + 1], 'w'
    jne invalid_w
    cmp byte [rbx + 2], NULL
    jne invalid_w

    ; ---------------------------------------------------------
    ; 5. Validate and copy word from argv[4]
    ; argv[4] is at [r10 + 32]
    ; Compute length, ensure <= MAXWORDLENGTH (to fit in array of size MAX+1)
    ; Copy characters to wordSaved (rcx) and null-terminate
    ; ---------------------------------------------------------
    mov rbx, [r10 + 32]          ; load pointer to word (argv[4])
    mov r9, 0                   ; counter = 0
len_check_loop:
    mov al, [rbx + r9]
    cmp al, NULL
    je len_check_done
    inc r9
    cmp r9, rdx
    ja invalid_word_len         ; jump if r9 > rdx (allow <= rdx)
    jmp len_check_loop
len_check_done:
    ; Now copy the word (manual loop)
    mov r11, [r10 + 32]          ; r11 = src pointer (argv[4])
    mov rdi, rcx                 ; rdi = dest pointer (wordSaved)
    mov rcx, 0                 ; rcx = copy index = 0
copy_loop:
    cmp rcx, r9                  ; if copy index >= length, done
    jge copy_done
    mov al, [r11 + rcx]          ; load byte from src at index
    mov [rdi + rcx], al          ; store byte to dest at index
    inc rcx                      ; increment index
    jmp copy_loop
copy_done:
    mov byte [rdi + rcx], NULL   ; null-terminate after copied chars

    ; ---------------------------------------------------------
    ; All checks passed - return true (1)
    ; ---------------------------------------------------------
    mov rax, TRUE
    jmp done

invalid_arg_count:
    mov rdi, invalidArgumentCount
    call printString
    mov rax, FALSE
    jmp done
invalid_f:
    mov rdi, invalidFArgument
    call printString
    mov rax, FALSE
    jmp done
invalid_w:
    mov rdi, invalidWArgument
    call printString
    mov rax, FALSE
    jmp done
invalid_file:
    mov rdi, invalidFile
    call printString
    mov rax, FALSE
    jmp done
invalid_word_len:
    mov rdi, invalidWord
    call printString
    mov rax, FALSE
    jmp done
done:
    pop rbx
    pop rbp
    ret

; rdi = char[] wordObtained (destination buffer)
; rsi = int MAXWORDLENGTH
; rdx = bool& isValid (reference to set validity flag)
; rcx = long long& fileDescriptor (reference to fd)
global getWord
getWord:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14                     ; save non-volatile registers

    ; ---------------------------------------------------------
    ; Initialize local registers and load parameters
    ; r8 = file descriptor (load from [rcx])
    ; r9 = wordObtained (rdi)
    ; r10 = MAXWORDLENGTH - 1 (for copy limit)
    ; r11 = &isValid (rdx)
    ; r14 = buffer base address (buffer)
    ; rbx = current position value (load from [buffCurr])
    ; ---------------------------------------------------------
    mov r8, [rcx]                ; load fd from reference
    mov r9, rdi                  ; dest buffer
    mov r10, rsi
    dec r10                      ; max copy positions (leave room for null)
    mov r11, rdx                 ; &isValid
    mov r14, buffer              ; r14 = absolute address of buffer
    mov rbx, [buffCurr]          ; rbx = current position value

    ; Quick check: if fd invalid (<0 or 0), early EOF
    cmp r8, 0
    jle eof_reached

    ; ---------------------------------------------------------
    ; Skip leading whitespace (characters <= SPACE_ASCII)
    ; Loop until non-whitespace or EOF
    ; ---------------------------------------------------------
skip_whitespace:
    cmp rbx, [buffIndex]
    jge refill_for_skip
    ; Bounds check: if rbx >= BUFFSIZE, force refill
    mov rax, BUFFSIZE
    cmp rbx, rax
    jae refill_for_skip
    movzx eax, byte [r14 + rbx]
    cmp eax, SPACE_ASCII
    jg start_word
    inc rbx
    jmp skip_whitespace
refill_for_skip:
    call refill_buffer
    cmp rax, 0
    jle eof_reached
    mov rbx, 0                   ; reset position after refill
    jmp skip_whitespace

start_word:
    ; Found start of word (eax holds first non-whitespace char)
    inc rbx                      ; advance past first char
    mov [buffCurr], rbx          ; update global position
    mov r13, 0                   ; r13 = total word length counter
    mov r12, 0                   ; r12 = copy position counter

    ; ---------------------------------------------------------
    ; Copy first character if room
    ; ---------------------------------------------------------
    cmp r12, r10
    jge skip_copy_first
    mov [r9 + r12], al
    inc r12
skip_copy_first:
    inc r13                      ; count the char regardless

    ; ---------------------------------------------------------
    ; Collect remaining word characters (> SPACE_ASCII)
    ; Continue until whitespace or EOF
    ; Keep special characters (anything > space)
    ; ---------------------------------------------------------
collect_next_char:
    cmp rbx, [buffIndex]
    jge refill_for_collect
    ; Bounds check
    mov rax, BUFFSIZE
    cmp rbx, rax
    jae refill_for_collect
    movzx eax, byte [r14 + rbx]
    inc rbx
    mov [buffCurr], rbx
    cmp eax, SPACE_ASCII
    jg process_char
    jmp end_word_collection
refill_for_collect:
    call refill_buffer
    cmp rax, 0
    jle end_word_collection
    mov rbx, 0                   ; reset position after refill
    mov [buffCurr], rbx
    ; Bounds check for new char
    movzx eax, byte [r14 + rbx]
    inc rbx
    mov [buffCurr], rbx
    cmp eax, SPACE_ASCII
    jg process_char
    jmp end_word_collection

process_char:
    ; Copy char if within length limit
    cmp r12, r10
    jge skip_copy
    mov [r9 + r12], al
    inc r12
skip_copy:
    inc r13                      ; increment total length
    jmp collect_next_char

end_word_collection:
    ; Null-terminate the copied portion
    mov byte [r9 + r12], NULL

    ; Update global buffer position (in case of refill)
    mov [buffCurr], rbx

    ; ---------------------------------------------------------
    ; Validate word: check if total length <= MAXWORDLENGTH
    ; Set isValid accordingly
    ; Always return true if a word was found (even if invalid length)
    ; to continue processing; validity checked in caller
    ; ---------------------------------------------------------
    cmp r13, rsi
    jbe word_is_valid           ; unsigned <=
    mov byte [r11], FALSE
    jmp return_success
word_is_valid:
    mov byte [r11], TRUE
return_success:
    mov rax, TRUE
    jmp function_done

eof_reached:
    mov byte [r11], FALSE
    mov rax, FALSE

function_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Internal function to refill the buffer
; Assumes r8 holds file descriptor
; Returns rax = bytes read (0 or negative on EOF/error)
; Sets buffIndex to bytes read, buffCurr to 0
refill_buffer:
    ; Quick check fd
    cmp r8, 0
    jl end_read                 ; invalid fd, early out
    push rcx                     ; save caller-saved (syscall clobbers)
    push rdx
    push r11                     ; save r11 (clobbered by syscall)
    mov rax, SYS_read
    mov rdi, r8                  ; file descriptor
    mov rsi, buffer              ; buffer address
    mov rdx, BUFFSIZE            ; max bytes to read
    syscall
    pop r11                      ; restore r11
    pop rdx
    pop rcx
    test rax, rax
    js end_read                 ; error (<0), set 0
    jz end_read                 ; EOF (0), set 0
    mov byte [buffer + rax], NULL ; null terminate
    mov [buffIndex], rax         ; store bytes read
    mov qword [buffCurr], 0      ; reset current position
    ret
end_read:
    mov qword [buffIndex], 0     ; set to 0 on error/EOF
    mov qword [buffCurr], 0
    mov rax, 0                 ; return 0
    ret

; rdi = char[] wordObtained
; rsi = char[] wordToCheck
; rdx = int& totalWords (reference to counter)
; Returns: RAX = TRUE if match, FALSE otherwise
global checkWord
checkWord:
    push rbp
    mov rbp, rsp

    ; ---------------------------------------------------------
    ; Compare wordObtained and wordToCheck character by character
    ; If exact match (including null terminator), increment counter and return TRUE
    ; Otherwise, return FALSE
    ; ---------------------------------------------------------
    mov rcx, rdi                 ; rcx = pointer to wordObtained
    mov r8, rsi                  ; r8 = pointer to wordToCheck

compare_loop:
    mov al, [rcx]                ; load next char from obtained
    cmp al, [r8]                 ; compare with toCheck
    jne mismatch                ; if not equal, no match
    cmp al, NULL                 ; check for end of string (both should hit null at same time)
    je match_found              ; if null, exact match
    inc rcx                      ; advance pointers
    inc r8
    jmp compare_loop

match_found:
    inc dword [rdx]              ; increment totalWords counter
    mov rax, TRUE                ; return TRUE
    jmp compare_done

mismatch:
    mov rax, FALSE               ; return FALSE

compare_done:
    pop rbp
    ret

; rdi = long long fileDescriptor
global closeFile
closeFile:
    push rbp
    mov rbp, rsp

    ; ---------------------------------------------------------
    ; Close the file using SYS_close syscall
    ; rdi already holds the file descriptor
    ; ---------------------------------------------------------
    mov rax, SYS_close
    syscall                      ; rax will hold result (0 on success)

    pop rbp
    ret

global getLength
getLength:
    mov	rax, 0
strCountLoop2:
    cmp	byte [rdi+rax], NULL
    je	strCountLoopDone2
    inc	rax
    jmp	strCountLoop2
strCountLoopDone2:
ret

global	printString
printString:
    ; -----
    ;  Count characters to write.

        mov	rdx, 0
    strCountLoop:
        cmp	byte [rdi+rdx], NULL
        je	strCountLoopDone
        inc	rdx
        jmp	strCountLoop
    strCountLoopDone:
        cmp	rdx, 0
        je	printStringDone

    ; -----
    ;  Call OS to output string.

        mov	rax, SYS_write			; system code for write()
        mov	rsi, rdi			; address of characters to write
        mov	rdi, STDOUT			; file descriptor for standard in
                            ; rdx=count to write, set above
        syscall					; system call

    ; -----
    ;  String printed, return to calling routine.

    printStringDone:
ret

section .note.GNU-stack noalloc noexec nowrite progbits
