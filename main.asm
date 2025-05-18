org 0x7c00

mov [boot_drive], dl  ; BIOS stores boot drive in dl

; Read at es:bx (0x0000:0x9000)
; mov bx, 0x9000
; mov dh, 2
; mov dl, [boot_drive]
; call read_disk

; Print first word read from first sector
; mov dx, [0x9000]
; call print_hex

; Print first word read from second sector
; mov dx, [0x9000 + 512]
; call print_hex

; Set text-mode to 3
mov ax, 0x3
int 0x10

mov si, real_hello
call bios_print

; Switch to 32-bit protected mode
cli
lgdt [gdt_descriptor]  ; Load GDT
mov eax, cr0           ; Make the switch:
or eax, 0x1            ; Set first bit
mov cr0, eax           ; of cr0 to 1

; Make a far jump (to a new segment) to our 32 bit code
; Forces the cpu to flush its cache and clear its pipeline
jmp CODE_SEG:protected_mode_init

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
bios_print:
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
    call bios_print             ; Print hex string
    popa
    ret

bits 32
; esi - String to print
print:
    pusha
    mov edx, 0xb8000
    add edx, 160      ; Print on second row
.loop:
    lodsb             ; Load byte at address esi in al, increment esi
    cmp al, 0         ; Check if byte is zero
    je .break         ; If byte is zero, we reached the end of the string
    mov ah, 0x0f
    mov [edx], ax
    add edx, 2
    jmp .loop
.break:
    popa
    ret

protected_mode_init:
    ; Point segment registers to data segment defined in GDT
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000  ; Update stack position 
    mov esp, ebp      ; at the top of free space

    call kernel_init

kernel_init:
    mov esi, protected_hello
    call print
    jmp $

; GDT Structure
; .null: Null Descriptor
; .code: Code Segment Descriptor
; .data: Data Segment Descriptor
gdt:
.null:
    dq 0x0
.code:
    ; base = 0x0, limit = 0xffff
    ; First flags  :: present     = 1, privilege      = 00, descriptor type = 1               => 1001b
    ; Type flags   :: code        = 1, conforming     =  0, readable        = 1, accessed = 0 => 1010b
    ; Second flags :: granularity = 1, 32-bit default =  1, 64-bit segment  = 0, AVL      = 0 => 1100b
    dw 0xffff     ; Limit (Bits  0 to 15)
    dw 0x0        ; Base  (Bits  0 to 15)
    db 0x0        ; Base  (Bits 16 to 23)
    db 10011010b  ; First flags, Type flags
    db 11001111b  ; Second flags, Limit (Bits 16 to 19)
    db 0x0        ; Base  (Bits 24 to 31)
.data:
    ; First flags and second flags are the same as code segment.
    ; Type flags   :: code        = 0, expand down     =  0, writable       = 1, accessed = 0 => 0010b
    dw 0xffff     ; Limit (Bits  0 to 15)
    dw 0x0        ; Base  (Bits  0 to 15)
    db 0x0        ; Base  (Bits 16 to 23)
    db 10010010b  ; First flags, Type flags
    db 11001111b  ; Second flags, Limit (Bits 16 to 19)
    db 0x0        ; Base  (Bits 24 to 31)
.end:

; GDT Descriptor Structure
gdt_descriptor:
    dw gdt.end - gdt - 1  ; GDT size
    dd gdt                ; GDT address

CODE_SEG equ gdt.code - gdt  ; Code Segment address
DATA_SEG equ gdt.data - gdt  ; Data Segment address

hex_pattern: db "0x0000", 0x0d, 0x0a, 0
hex_table:   db "0123456789abcdef"
read_error:  db "ERROR: Failed to read disk", 0x0d, 0x0a, 0
boot_drive:  db 0

real_hello:       db "Started in real mode",     0
protected_hello:  db "Landed in protected mode", 0

times 510-($-$$) db 0  ; Zero padding
dw 0xaa55              ; Magic number

; Add extra sectors after the boot sector
; Read will fail if sectors do not exist
times 256 dw 0xaaaa
times 256 dw 0xbbbb

; vim:ft=nasm
