.DEFAULT_GOAL = run

os.bin:
	i386-elf-gcc -T linker.ld -o $@ -ffreestanding -O2 -nostdlib -Wall -g -lgcc kernel.c systables.s boot.s

%.bin:
	i386-elf-as $*.s -o $*.o
	i386-elf-ld $*.o -o $*.elf
	i386-elf-objcopy $*.elf $@ -O binary

clean:
	rm -rf *.bin *.o *.elf *.iso ./grubdir

os.iso: os.bin user_program.bin
	mkdir -p grubdir/boot/grub
	mv $< grubdir/boot/
	echo "menuentry \"os\" {\nmultiboot /boot/$<\nmodule /modules/program}" > grubdir/boot/grub/grub.cfg
	mkdir -p grubdir/modules
	mv $(word 2,$^) grubdir/modules/program
	grub-mkrescue -o $@ grubdir

run: os.iso
	qemu-system-x86_64 -cdrom $^

debug: os.elf os.iso
	qemu-system-x86_64 -s -cdrom os.iso &
	i386-elf-gdb -ex "target remote localhost:1234" -ex "symbol-file os.elf"
