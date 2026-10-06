bits 16

segment _ENTRY public class=CODE use16

;
; CODE
;
global start_
global drive_number
extern _cstart_

start_:

    ; Stage 1 gives us the drive number in dl
    mov [drive_number], dl

    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00

    sti

    xor ax, ax
    mov al, dl
    push ax
    call _cstart_
    add sp, 2

.halt:
    cli
    hlt
    jmp .halt


drive_number:                   db 0