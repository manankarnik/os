org 0x7c00

mov dx, 0x1fc6
call print_hex
jmp $

print:
    pusha
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .break
    int 0x10
    jmp .loop
.break:
    popa
    ret

print_hex:
    pusha
    mov si, hex_pattern
    mov cl, 12
    mov di, 2
.loop:
    mov bx, dx
    shr bx, cl
    and bx, 0x000f
    mov bx, [bx + hex_table]
    mov [hex_pattern + di], bl
    inc di
    sub cl, 4
    cmp di, 6
    je .break
    jmp .loop
.break:
    mov si, hex_pattern
    call print
    popa
    ret

hex_pattern:
    db "0x0000", 0x0D, 0x0A, 0
hex_table:
    db "0123456789abcdef"

times 510-($-$$) db 0
dw 0xaa55
