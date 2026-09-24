; Bios loads from 0x7C00 address, so tell the assembler
; to start from there
org 0x7C00

; Use 16 bits for the code
bits 16

;
; NASM MACROS
;
%define NEWLINE 0x0D, 0x0A      ; Linefeed + Carriage return characters

start:
    ; Go to main, ignore all function definitions
    jmp main


;
; Print a null terminated string to the screen
; Params:
;   - ds:si points to the string
;
puts:
    ; Save register values so that they can be returned back after execution
    push si                     ; Save Source Index
    push ax                     ; Save Entirety of the A register (Low and High)

.loop:
    ; Load character into al, then increment source pointer index
    mov al, [si]
    inc si

    ; Check if character is null
    or al, al                   ; or does a bitwise OR, then saves result to left operand
                                ; NOTE: Also sets flags in flag register, like zero flag

    ; If character is NULL, stop printing
    jz .end                     ; Jump to .end if zero flag is set


    ; Use BIOS interrupts to print the string
    mov ah, 0x0E                ; Call bios interrupt
    mov bh, 0x00                ; Page number 0

    ; Here the character to print is character in 'al'
    ; Print that bad boy
    int 0x10                    ; Print character interrupt (Handled by BIOS signal handler)
    
    ; Otherwise keep looping
    jmp .loop

.end:
    ; Revert register values
    pop ax
    pop si
    ret    


;
; Main function!!
;
;
main:

    ; Setup data segments
    mov ax, 0
    mov ds, ax
    mov es, ax


    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00      ; stack grows downwards from where we are in memory
                        ; anything after 0x7X00 is our OS! setting stack at
                        ; at the end will make it overwrite the OS


    ; Print hello world! 
    mov si, hello_world
    call puts

    hlt

.halt:
    jmp .halt



hello_world: db "Hello, World!", NEWLINE, 0



; Fill the space upto byte 510 with 0x00
; Number of 0 bytes required to reach 510:
; 510 - (current position($) - start of current section($$))
; Thus $-$$ is size of our program
times 510-($-$$) db 0

; Write the signature which the bios looks for
; dw writes a word (2 bytes), db writes 1 byte
dw 0AA55h
