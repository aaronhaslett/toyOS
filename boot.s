.set FLAGS, 0x00000002
.set MAGIC, 0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)

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
.align 0x1000
.global high_half_base
.set high_half_base, 0xC0000000
boot_page_dir:
    .long 0x00000083
    .rept (high_half_base >> 22) - 1
        .long 0
    .endr
    .long 0x00000083

.align 16
.extern kernel_virtual_start
.extern kernel_physical_start
.extern kernel_size

.global _start
.type _start, @function
_start:
    movl $boot_page_dir - high_half_base, %ecx
    movl %ecx, %cr3

    movl %cr4, %ecx
    orl $0x00000010, %ecx
    movl %ecx, %cr4

    movl %cr0, %ecx
    orl $0x80000001, %ecx
    movl %ecx, %cr0
    lea (_higher_half_start), %ecx
    jmp *%ecx
_higher_half_start:

    mov $stack_top, %ebp
    mov $stack_top, %esp

    call init

    movl %esp, %ebp
    push %ebx
    push $kernel_size
    push $kernel_physical_start
    push $kernel_virtual_start
    call kernel_main
    hlt

    cli
    1:hlt
    jmp 1b

.size _start, . - _start
