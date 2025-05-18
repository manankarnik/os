org 0x7c00
mov [boot_drive], dl  ; BIOS stores boot drive in dl

; Move stack out of the way
mov bp, 0x8000
mov sp, bp

; Read at es:bx (0x0000:0x9000)
mov bx, 0x9000
mov dh, 2
mov dl, [boot_drive]
call read_disk

; Print first word read from first sector
mov dx, [0x9000]
call print_hex

; Print first word read from second sector
mov dx, [0x9000 + 512]
call print_hex
jmp $

; es:bx - Memory location to read to
; dh    - No. of sectors to read
; dl    - Disk to read from
read_disk:
    pusha
    push dx             ; Push dx to store no. of sectors
    mov ah, 0x02        ; BIOS Read Sector Routine
    mov al, dh          ; No. of sectors to read
    mov ch, 0x00        ; Cylinder 0
    mov dh, 0x00        ; Head 0
    mov cl, 0x02        ; Sector 2 (1 indexed)

    int 0x13
    jc .error           ; Carry flag is set if read failed
    pop dx              ; Pop dx to retrieve no. of sectors expected
    cmp dh, al          ; No. of sectors actually read in al
    jne .error
    jmp .break
.error:
    mov si, read_error  ; Print error message
    call print 
    mov dx, ax
    call print_hex
.break:
    popa
    ret

; si - String to print
print:
    pusha
    mov ah, 0x0e  ; BIOS Scrolling Teletype Routine
.loop:
    lodsb         ; Load byte at address si in al, increment si
    cmp al, 0     ; Check if byte is zero
    je .break     ; If byte is zero, we reached the end of the string
    int 0x10
    jmp .loop
.break:
    popa
    ret

; dx - Number to print as hex
print_hex:
    pusha
    mov si, hex_pattern         ; Initiallly 0x0000
    mov cl, 12                  ; Amount of bits to shift
    mov di, 2                   ; Index in si to replace. 0x remains the same
.loop:
    mov bx, dx                  ; Copy dx
    shr bx, cl                  ; Shift right cl bits
    and bx, 0x000f              ; Bitmask for the least significant bit
    mov bx, [bx + hex_table]    ; Get the corresponding hex character from table
    mov [hex_pattern + di], bl  ; Replace pattern character with hex character
    inc di                      ; Increment index
    sub cl, 4                   ; Reduce shift by 4 (1 byte)
    cmp di, 6                   ; Check if index == len(0x0000)
    je .break
    jmp .loop
.break:
    mov si, hex_pattern         ; Print hex string
    call print
    popa
    ret

hex_pattern: db "0x0000", 0x0d, 0x0a, 0
hex_table:   db "0123456789abcdef"
read_error:  db "ERROR: Failed to read disk", 0x0d, 0x0a, 0
boot_drive:  db 0

times 510-($-$$) db 0
dw 0xaa55

; Add extra sectors after the boot sector
; Read will fail if sectors do not exist
times 256 dw 0xaaaa
times 256 dw 0xbbbb

; vim:ft=nasm
