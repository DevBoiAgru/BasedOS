bits 16

segment _TEXT public class=CODE use16

global _bios_putc

;
; Print a null terminated string to the screen
; Params:
;   - Character
_bios_putc:
    push bp
    mov bp, sp
    push bx

    ; [BP + 0] is old call frame
    ; [BP + 2] is return addr
    ; [BP + 4] is the character

    ; Use BIOS interrupts to print the character
    mov ah, 0x0E                ; Bios interrupt
    mov bh, 0                   ; Page number
    mov al, [bp + 4]            ; Character
    ; Here the character to print is character in 'al'
    ; Print that bad boy
    int 0x10                    ; Print character interrupt (Handled by BIOS signal handler)
    
    ; Restore registers
    pop bx
    pop bp
    ret