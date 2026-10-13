bits 16

segment _TEXT public class=CODE use16

global _bios_putc
global _bios_disk_read

; Stage 2 main.asm has this defined
extern drive_number

;
; Print a null terminated string to the screen
; Params:
;   - Character
_bios_putc:
    push bp
    mov bp, sp
    push bx
    push si
    push di
    push ds
    push es

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
    pop es
    pop ds
    pop di
    pop si
    pop bx
    pop bp
    ret

;
; Disk functions
;

;
; Disk read
; Params:
;   - Number of sectors to read
;   - Segment for destination buffer address
;   - Offset for destination buffer address
;   - LBA to read
; Returns:
;   - 0 if no error
;   - 1 if error
_bios_disk_read:
    ; Save call frame
    push bp
    mov  bp, sp


    ; Push whatever is modified in bios calls
    push ds
    push ax
    push bx
    push cx
    push dx

    ; Verify extended LBA support in the bios
    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [drive_number]
    int 0x13
    ; If bios call failed carry flag is set
    jc .error

    ; Now  we should have flags in the CX register for supported commands
    ; for our case we need to check if bit 0 is set
    test cx, 1
    ; If the LSB in CX is 0, zero flag is 1. (cx was 0)
    ; thus bios doesnt supoprt extended mode lba
    jz .error


    ; Restore whatever values were there before the bios call
    pop dx
    pop cx
    pop bx


    ; Zero out the DS segment register, we only need offset for the DAP address
    ; since its saved in this sector itself (Within 512 bytes)
    xor ax, ax
    mov ds, ax

    ; Put appropriate values in the disk address packet

    mov ax,  [bp + 4]
    mov [dap_sector_count], ax
    
    mov ax,  [bp + 6]
    mov [dap_transfer_buffer_off], ax

    mov ax,  [bp + 8]
    mov [dap_transfer_buffer_seg], ax

    mov ax, [bp + 10]   ; Lowest word
    mov [dap_lba], ax

    mov ax, [bp + 12]   ; Second lowest
    mov [dap_lba + 2], ax

    mov ax, [bp + 14]   ; Second highest
    mov [dap_lba + 4], ax

    mov ax, [bp + 16]   ; Highest word
    mov [dap_lba + 6], ax
    

    ; Retry count
    mov ah, 3

.retry:

    ; Call the bios to read the disk
    push bx
    push cx
    push dx

    mov si, disk_address_packet
    mov ah, 0x42
    mov dl, [drive_number]                ; Read whatever drive the bios gave us
    int 0x13

    ; Error handling

    pop dx
    pop cx
    pop bx
    jnc .success

    dec ah
    test ah, ah

    ; BIG WARNING!! This does NOT account for when number of retries
    ; are exhausted, i.e it will go to success anyways if it doesnt
    ; succeed in 3 tries but its ok because modern drives and bioses 
    ; are good
    jnz .retry

.success:
    pop ax
    pop ds

    ; Restore call frame
    pop bp

    ; Success return code
    mov ax, 0

    ret

.error:
    pop dx
    pop cx
    pop bx
    pop ds
    pop ax

    mov ax, 1
    pop ds
    pop bp
    ret


;
; Disk Address Packet (For disk instructions via int 13h)
;
align 4
disk_address_packet:
    dap_packet_size                 db 0x10     ; 16 bytes
    dap_zero                        db 0x00     ; Always zero. Idk why
    dap_sector_count                dw 0x00     ; Number of sectors to read

    ; (Ordered as Offset:Segment because of little endian)
    dap_transfer_buffer_off         dw 0x00     ; Offset for address of target buffer
    dap_transfer_buffer_seg         dw 0x00     ; Segment for address of target buffer

    dap_lba                         dq 0x00     ; Address on the disk

