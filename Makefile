.DEFAULT_GOAL = run

%.o: %.s
	i386-elf-as $< -o $@

%.o: %.c
	i386-elf-gcc -c $< -o $@ -std=gnu99 -ffreestanding -O2 -Wall -Wextra

os.o: boot.o kernel.o
	i386-elf-gcc -T linker.ld -o $@ -ffreestanding -O2 -nostdlib -lgcc $^

os.bin: boot.o kernel.o
	i386-elf-gcc -T linker.ld -o $@ -ffreestanding -O2 -nostdlib -lgcc $^

clean:
	rm -rf bochslog.txt grub.cfg *.bin *.o ./grubdir *.iso

os.iso: os.bin
	mkdir -p grubdir/boot/grub
	mv $^ grubdir/boot/
	echo "menuentry \"os\" {multiboot /boot/$^}" > grubdir/boot/grub/grub.cfg
	tree
	grub-mkrescue -o $@ grubdir

run: os.iso
	qemu-system-x86_64 -cdrom $^
	#bochs -f bochsrc.txt -q
