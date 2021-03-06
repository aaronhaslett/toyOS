.set NUM_INTERRUPTS, 100 //must be >= 15
.set VID_MEM, 0xc00b8000
.set WoB, 0x0f
.altmacro

.section .text

/*
 * GDT section
 */
gdt_start:
    .long 0, 0
.irp priv_bits,0,3 //kernel, then user
    .irp exec_bit,1,0 //Code then data segment.  Do not change order.
        access = 0x92 | (exec_bit << 3) | (priv_bits << 5)
        .byte 0xff, 0xff, 0x0, 0x0, 0x0, access, 0xcf, 0x0
    .endr
.endr
gdt_end_descriptor:
    .short (gdt_end_descriptor - gdt_start) - 1
    .long gdt_start

/*
 * IDT section
 */
idt_start:
    .short idt_end - idt_gates_start - 1
    .long idt_gates_start

.macro idt_entry index
    .long handler_\index//High two bytes (linearly 2nd) of this will be replaced with kernel selector during init.
    .byte 0x0, 0x8e, 0xbe, 0xef//0xBEEF will be replaced with high bits of handler reference.
.endm

i = 0
idt_gates_start:
.rept NUM_INTERRUPTS
    idt_entry %i
    i = i + 1
.endr
idt_end:

/*
 * IDT handlers.
 * Macro defined to produce handlers that build up the right stack before
 * calling the common callback that calls the root handler written in C.
 */
.macro handler int_num has_error_code
    handler_\int_num: //This is the label that the IDT entries will point to.
    cli

    pusha
    .if (\int_num == 33) //For keyboard, save the scancode
        movl $0x0, %eax
        inb $0x60, %al
    .else
        .ifnb has_error_code //For exceptions with error codes, pop it from the stack.
            pop %eax
        .endif
    .endif
    movl $\int_num, %ebx//save interrupt number.  root_handler will get this.

    call interrupt_callback

    movb $0x20, %al //EOI (End Of Interrupt) code to send to PICs
    .if \int_num >= 40 //EOI slave if it produced the interrupt
        outb %al, $0xA0
    .endif
    outb %al, $0x20 //Always EOI master because even if slave sent the interrupt, it went through master.

    popa

    sti
    iret
.endm

//Construct handlers by calling the handler macro with 'true' if the interrupt has an error code, or with nothing otherwise.
.irp interrupt,0,1,2,3,4,5,6,7,9
    handler %\interrupt
.endr
.irp interrupt_with_error_code,8,10,11,12,13,14
    handler %\interrupt_with_error_code, "true"
.endr

//After interrupt 14, no interrupts have error codes
i = 15
.rept NUM_INTERRUPTS - 15
    handler %i
    i = i + 1
.endr

/*
 * Common interrupt handler code.  Load kernel data selector, call root_handler (C), restore selector and stack.
 */
num_interrupts:
    .byte 0

.macro update_sels_from_cx
    movw %cx, %ds
    movw %cx, %ss
    movw %cx, %es 
    movw %cx, %fs 
    movw %cx, %gs 
.endm

interrupt_callback:
    incb num_interrupts
    movb num_interrupts, %cl
    addb $48, %cl
    movb %cl, VID_MEM(,1)
    movb $WoB, 1+VID_MEM(,1)

    mov %ds, %cx
    push %ecx
    movw $0x10, %cx
    update_sels_from_cx

    push %eax
    push %ebx

    call root_handler

    add $8, %esp

    pop %ecx
    update_sels_from_cx
    ret

/*
 * Initialise routine.  Load GDT, fix IDT handler references, load IDT, initialise PIC.
 */
.global init
.type init, @function
init:
    pusha

    //load IDT
    movl $gdt_end_descriptor, %eax
    lgdt (%eax)
    jmp $0x08, $_here
_here:
    movw $0x10, %cx
    update_sels_from_cx

    //Fix IDT handler pointers
    movl $idt_gates_start, %ebx
    loop:
        movw 2(%ebx), %dx//Get high 16 bits of handler pointer
        movw $0x08, 2(%ebx)//Put 16 bit kernel selector where high bits of pointer were
        movw %dx, 6(%ebx)//Put the high bits where they belong (last 2 bytes)
        addl $8, %ebx//Move to next IDT entry
        cmpl $idt_end-4, %ebx//If we're now beyond the last entry, stop.
        jl loop

    //Load our fixed IDT
    movl $idt_start, %eax
    lidtl (%eax)

    //start init sequence for PICs, ICW4=true
    movb $0x11, %al
    outb %al, $0x20
    outb %al, $0xA0

    //init master PIC with timer masked, offset 32
    .irp cmdbyte, 0x20, 0x04, 0x05, 0x01
        movb $\cmdbyte, %al;
        outb %al, $0x21
    .endr
    //init slave PIC with nothing masked, offset 40
    .irp cmdbyte, 0x28, 0x02, 0x01, 0x00
        movb $\cmdbyte, %al;
        outb %al, $0xA1
    .endr

    popa
    sti
    ret
