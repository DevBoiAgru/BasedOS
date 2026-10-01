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


    ; Print hello world! 
    mov si, hello_world
    call puts


;
; ERROR HANDLING
;
wait_key_and_reboot:
    mov ah, 0
    int 16h             ; Wait for keypress
    jmp 0xFFFF          ; Jump to beginning of BIOS, thus reboot

.halt:
    cli                 ; Disable interrupts so that CPU cannot get out of halt state    
    jmp .halt



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
;   - 


;
; Disk Address Packet
;
dap_packet_size                 db 0x10     ; 16 bytes
dap_zero                        db 0x00     ; Always zero? Idk why
dap_sector_count                dw 0x00     ; Number of sectors to read
dap_transfer_buffer             dd 0x00     ; Segment:Offset for address of target buffer
dap_lba                         dq 0x00     ; Address on the disk

;
; Data
;
hello_world:                    db "Hello from the bootloader!", NEWLINE, 0
drive_number:                   db 0


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
