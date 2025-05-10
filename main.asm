org 0x7c00

mov ah, 0x0e
mov si, msg
print:
    mov al, [si]
    cmp al, 0
    je loop
    int 0x10
    lodsb
    jmp print

loop:
    jmp $

msg: db "Hello world!", 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xaa55
