main.bin: main.nasm
	nasm -fbin -o main.bin main.nasm

run: main.bin
	qemu-system-x86_64 main.bin

clean:
	rm -f main.bin
