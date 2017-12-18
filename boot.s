.set FLAGS, 0b0000000000000011
.set MAGIC, 0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)
.set VID_MEM, 0xb8000
.set WoB, 0x0f

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

.section .text
.include "systables.s"

.global _start
.type _start, @function
_start:
    mov $stack_bottom, %ebp
    mov $stack_bottom, %esp

    call init
    call kernel_main

    cli
    1:hlt
    jmp 1b

.size _start, . - _start
