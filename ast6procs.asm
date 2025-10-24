; *****************************************************************
; Name: John Doe
; NSHE_ID: 0123456789
; Section: 9999
; Assignment: 2
; Description: Testing description for values or something idk
; *****************************************************************

%macro findLength 1
    mov rdx, 0  ; set counter to 0
    %%obtainLength:
        ; increment counter until null is found
        cmp byte[%1+rdx], NULL
        je %%endLength
        inc rdx
        jmp %%obtainLength
    %%endLength:
    ; once null is found, finish the macro

%endmacro

%macro cout 1

    ; Prints out the provided string
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, %1

    ; finds the lenght based on the provided string
    findLength %1
    syscall

%endmacro

%macro endl 0
    ; Prints out a newline only
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, nlMessage
    mov rdx, 1
    syscall
%endmacro

%macro pushArgs 0
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9
%endmacro

%macro popArgs 0
    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
%endmacro

section .data
TRUE equ 1
FALSE equ 0
NULL equ 0
LF equ 10
NEWLINE equ 10

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
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

invalidArgumentCount db "You have given an invalid command line argument. Make sure it follows this format:",NEWLINE," ./main -f <fileName> -w <word>", NULL
invalidFArgument db "Your first argument is not -f.", NEWLINE ,NULL
invalidWArgument db "Your second argument is not -w.", NEWLINE, NULL
invalidFile db "You did not open a valid file. Try Again", NEWLINE, NULL
invalidWord db "Your word has exceded the limit of MAXWORDLENGTH", NEWLINE, NULL
nlMessage db NEWLINE, NULL

BUFFSIZE equ 300000
buffIndex dq BUFFSIZE
buffCurr dq BUFFSIZE
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

ret

; rdi = char[] wordObtained
; rsi = int MAXWORDLENGTH
; rdx = bool& isValid
; rcx = long long& fileDescriptor
global getWord
getWord:

ret

; rdi = char[] wordObtained
; rsi = char[] wordToCheck
; rdx = int& totalWords
global checkWord
checkWord:

ret

; rdi = long long fileDescriptor
global closeFile
closeFile:

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