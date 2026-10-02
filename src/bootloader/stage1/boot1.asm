; Bios loads from 0x7C00 address, so tell the assembler
; to start from there
org 0x7C00

; Use 16 bits for the code
bits 16

;
; NASM MACROS
;
%define NEWLINE 0x0D, 0x0A      ; Linefeed + Carriage return characters

;
; CODE
;
start:
    ; Go to main, ignore all function definitions (If any)
    jmp main

;
; Main function!!
;
main:
    ; Setup data segment registers, set them to zero indirectly since we cannot do that directly
    mov ax, 0
    mov ds, ax
    mov es, ax


    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00      ; stack grows downwards from where we are in memory
                        ; anything after 0x7X00 is our OS! setting stack at
                        ; at the end will make it overwrite the OS

    ; Bios gives us the drive, 0x00 for floppy, 0x80 for hard disk. Save this information for later
    mov [drive_number], dl

    ; Print newlines to differentiate bios output from bootloader output! 
    mov si, str_newlines
    call puts

    ; Print hello world! 
    mov si, str_hello_world
    call puts

    ; Read second sector (LBA=1), at location 0x8000
    ; Second sector stores the second stage of the bootloader
    mov al, 1
    mov cx, 0
    mov dx, 0x8000
    mov bx, 1
    call disk_read

    jmp 0x8000
    call puts

    cli
    hlt


;
; Function Definitions
;

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
; Disk functions
;

;
; Disk read
; Params:
;   - al: Number of sectors to read
;   - cx: Segment for destination buffer address
;   - dx: Offset for destination buffer address
;   - bx: LBA to read
disk_read:
    ; Save all the registers we modify in the function
    push ds
    push ax
    push bx
    push cx
    push dx

    ; Push whatever is modified in bios calls
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
    jc err_bios_doesnt_support_extended_mode


    ; Now  we should have flags in the CX register for supported commands
    ; for our case we need to check if bit 0 is set
    test cx, 1
    ; If the LSB in CX is 0, zero flag is 1. (cx was 0)
    ; thus bios doesnt supoprt extended mode lba
    jz err_bios_doesnt_support_extended_mode


    ; Restore the function call arguments
    pop dx
    pop cx
    pop bx
    pop ax

    push ax
    ; Zero out the DS segment register, we only need offset for the DAP address
    ; since its saved in this sector itself (Within 512 bytes)
    xor ax, ax
    mov ds, ax
    pop ax

    ; Put appropriate values in the disk address packet
    mov [dap_sector_count], al
    mov [dap_transfer_buffer_off], dx
    mov [dap_transfer_buffer_seg], cx
    mov [dap_lba], bx

    ; Retry count
    mov ah, 3

.retry:

    ; Call the bios to read the disk
    pusha
    stc                                   ; Bios clears this on success
    mov si, disk_address_packet
    mov ah, 0x42
    mov dl, [drive_number]                ; Read whatever drive the bios gave us
    int 0x13

    ; Error handling
    popa
    jnc .success

    dec ah
    test ah, ah
    jnz .retry


.success
    pop dx
    pop cx
    pop bx
    pop ax
    pop ds

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



;
; ERROR HANDLING
;
wait_key_and_reboot:
    mov ah, 0
    int 16h             ; Wait for keypress
    jmp 0xFFFF          ; Jump to beginning of BIOS, thus reboot

err_bios_doesnt_support_extended_mode:
    mov si, str_err_no_extended_mode
    call puts
    jmp wait_key_and_reboot



;
; Data
;
drive_number:                   db 0

str_newlines:                   db NEWLINE, NEWLINE, 0
str_hello_world:                db "INFO: Hello from the bootloader!", NEWLINE, 0
str_err_no_extended_mode:       db "ERROR: Bios does not support extended mode!", NEWLINE, 0


; Fill the space upto byte 446 with 0x00
; This is all the space we have for the stage 1 bootloader
; Number of 0 bytes required to reach 446:
; 446 - (current position($) - start of current section($$))
; Thus $-$$ is size of our program
times 446-($-$$) db 0

;
; MBR Partition table
;
; Partition 1 Entry - 16 Bytes
part_boot_indicator             db 0x80                     ; Bootable (0x00 is inactive)
part_starting_head              db 0xFF                     ; Random gibberish for obsolete CHS
part_starting_chs               db 0xFF, 0xFF               ; Same as above
part_starting_sysID             db 0x0C                     ; FAT32 Partition with LBA support
part_ending_head                db 0xFF                     ; Random gibberish for obsolete CHS
part_ending_chs                 db 0xFF, 0xFF               ; Same as above
part_relative_lba               dd 2048                     ; Partition start after 2048 sectors (1MiB)
part_total_sectors              dd 129024                   ; Number of sectors in the partition (Sectors in 64 MB - relative_lba)
                                                            ; Total Sectors = SIZE(MB) * 1024 * 1024 / 512

; Fill 0s for the 3 other partitions (16 byte entry each)
times 16 * 3 db 0

; Write the signature which the bios looks for
; dw writes a word (2 bytes), db writes 1 byte
dw 0xAA55
