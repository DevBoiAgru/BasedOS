; Bios loads from 0x7C00 address, so tell the assembler
; to start from there
org 0x7C00

; Use 16 bits for the code
bits 16

;
; NASM MACROS
;
%define NEWLINE 0x0D, 0x0A      ; Linefeed + Carriage return characters


; FAT12 HEADER
jmp short start
nop

bdb_oem:                            db 'MSWIN4.1'   ; 8 bit OEM string
bdb_bytes_per_sector:               dw 512          ; Number of bytes in sectors
bdb_sectors_per_cluster:            db 1
bdb_reserved_sectors:               dw 1
bdb_fat_count:                      db 2
bdb_dir_entries_count:              dw 0x0E0
bdb_total_sectors:                  dw 2880
bdb_media_descriptor_type:          db 0x0F0        ; F0 = 3.5 inch floppy
bdb_sectors_per_fat:                dw 9            ; 9 sectors/fat
bdb_sectors_per_track:              dw 18
bdb_heads:                          dw 2
bdb_hidden_sectors:                 dd 0
bdb_large_sector_count:             dd 0

; extended boot record
ebr_drive_number:                   db 0                        ; 0x00 floppy, 0x80 hdd, useless
                                    db 0                        ; reserved
ebr_signature:                      db 29h
ebr_volume_id:                      db 0x69, 0x67, 0xFA, 0xCE   ; serial number
ebr_volume_label:                   db 'BASED_DISK '            ; 11 bytes, padded with spaces
ebr_system_id:                      db 'FAT12   '               ; 8 bytes


;
; CODE
;

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

    ; Read something from disk
    ; BIOS sets DL to drive number
    mov [ebr_drive_number], dl

    ; Call the read function
    mov ax, 1           ; Read LBA=1
    mov cl, 1           ; Read second sector
    mov bx, 0x7E00      ; Data after bootloader
    call disk_read

    cli                 ; Disable interrupts so that CPU does not escape halt
                        ; if we press a key or something
    hlt


;
; ERROR HANDLING
;

floppy_error:
    mov si, str_floppy_fail
    call puts
    jmp wait_key_and_reboot


wait_key_and_reboot:
    mov ah, 0
    int 16h             ; Wait for keypress
    jmp 0xFFFF          ; Jump to beginning of BIOS, thus reboot

.halt:
    cli                 ; Disable interrupts so that CPU cannot get out of halt state    
    jmp .halt


;
; DISK FUNCTIONS
;

;
; Converts LBA (Logical Block Address) to CHS (Cylinder Heaed Sector)
; Parameters:
;   - ax: LBA
; Returns:
;   - cx - bits[0-5]: Sector
;   - cx - bits[6-15]: Cylinder
;   - dh - head
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx          ; Clear dx to 0
    div word [bdb_sectors_per_track]
        ; Division in ax    (LBA / sectorspertrack)
        ; Remainder in dx   (LBA % sectorspertrack

    inc dx              ; dx = (LBA % sectorspertrack) + 1
    mov cx, dx

    xor dx, dx          ; dx = 0
    div word [bdb_heads]
        ; ax = (LBA / sectorspertrack) / heads = cylinder
        ; dx = (LBA / sectorspertrack) /% heads = head

    mov dh, dl          ; dh = head
    mov ch, al          ; ch = cylinder (lower 8 bits)
    shl ah, 6

    or cl, ah           ; put upper 2 bits of cylinders in CL

    pop ax
    mov dl, al
    pop ax
    ret

;
; Read sectors from disk
; Parameters:
;   - ax: LBA
;   - cx: number of sectors to read (upto 128)
;   - dl: drive number
;   - es:bx: memory address of where to store the data we read
;
disk_read:
    push di
    push dx
    push cx
    push bx
    push ax

    call lba_to_chs
    pop ax              ; Store number of sectors to read in ax
    
    mov ah, 0x02
    mov di, 3           ; Retry amount

.retry:
    pusha               ; Save all registers
    stc                 ; Set carry flag because some BIOS forget
    int 13h             ; BIOS interrupt to read
    jnc .done           ; Get out of loop if carry is set (because we succeeded)

    ; Read fail
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry          ; If di is not zero yet jump back to loop

.floppy_fail:
    ; All retry attempts failed
    ; Show an error message and stop booting    
    jmp floppy_error

.done:

    ; Restore registers
    pop bx
    pop cx
    pop dx
    pop di

    ;pop di
    ;pop dx
    ;pop cx
    ;pop bx
    ;pop ax
    ret

;
; Reset Disk Controller
; Parameters:
;   - dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


hello_world:                    db "Hello, World!", NEWLINE, 0
str_floppy_fail:               db "Floppy Error! Cannot boot", NEWLINE, 0



; Fill the space upto byte 510 with 0x00
; Number of 0 bytes required to reach 510:
; 510 - (current position($) - start of current section($$))
; Thus $-$$ is size of our program
times 510-($-$$) db 0

; Write the signature which the bios looks for
; dw writes a word (2 bytes), db writes 1 byte
dw 0AA55h
