bits 16

segment _ENTRY public class=CODE use16

;
; CODE
;
global start_
extern _cstart_

start_:
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