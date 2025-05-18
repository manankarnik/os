main.bin: main.asm
	nasm -fbin -o main.bin main.asm

run: main.bin
	qemu-system-x86_64 main.bin

clean:
	rm -f main.bin
