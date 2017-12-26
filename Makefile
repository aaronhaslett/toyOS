.DEFAULT_GOAL = run

os.%:
	i386-elf-gcc -T linker.ld -o $@ -ffreestanding -O2 -nostdlib -Wall -g -lgcc kernel.c systables.s boot.s

clean:
	rm -rf bochslog.txt grub.cfg *.bin *.o *.elf ./grubdir *.iso

os.iso: os.bin
	mkdir -p grubdir/boot/grub
	mv $^ grubdir/boot/
	echo "menuentry \"os\" {multiboot /boot/$^}" > grubdir/boot/grub/grub.cfg
	tree
	grub-mkrescue -o $@ grubdir

run: os.iso
	qemu-system-x86_64 -cdrom $^
	#bochs -f bochsrc.txt -q

debug: os.elf os.iso
	qemu-system-x86_64 -s -cdrom os.iso &
	i386-elf-gdb -ex "target remote localhost:1234" -ex "symbol-file os.elf"
