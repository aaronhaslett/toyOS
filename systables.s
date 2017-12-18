.set NUM_INTERRUPTS, 100 //must be >= 15
.altmacro

/*
 * GDT section
 */
gdt_start:
    .long 0
    .long 0
gdt_code:
    .short 0xffff
    .short 0
    .byte 0
    .byte 0x9a
    .byte 0b11001111
    .byte 0
gdt_data:
    .short 0xffff
    .short 0
    .byte 0
    .byte 0x92
    .byte 0b11001111
    .byte 0
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
     .long handler_\index
    //.short 0x08 //kernel segment selector, to be added.
    .byte 0 //always 0
    .byte 0x8e //flags
    .short 0xcafe  //high offset, to be fixed
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
 * Macro defined to conditionally produce handlers that build up the right stack before calling the common callback that calls the root handler written in C.
 */
.macro handler index ec
    handler_\index://This is the label that the IDT entries will point to.
    cli
    pusha
    .if (\index == 33)//For keyboard, push the scancode
        movl $0x0, %eax
        inb $0x60, %al
        push %eax
    .else
        .ifb ec//For exceptions without error codes, push 0 to keep stack consistent.
            push $0
        .endif
    .endif
    push $\index//Push interrupt number.  root_handler will get this.
    call interrupt_callback

    movb $0x20, %al
    .if \index >= 40
        outb %al, $0xA0
    .endif
    outb %al, $0x20
    add $8, %esp
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

//after interrupt 14, no interrupts have error codes
i = 15
.rept NUM_INTERRUPTS - 15
    handler %i
    i = i + 1
.endr

/*
 * Common interrupt handler code.
 */
num_interrupts:
    .byte 0

.macro update_sels_from_ax
    movw %ax, %ds
    movw %ax, %ss
    movw %ax, %es 
    movw %ax, %fs 
    movw %ax, %gs 
.endm

interrupt_callback:
    incb num_interrupts
    movb num_interrupts, %al
    addb $48, %al
    movb %al, VID_MEM(,1)
    movb $WoB, 1+VID_MEM(,1)

    mov %ds, %ax
    push %eax
    movw $0x10, %ax
    update_sels_from_ax

    call root_handler

    pop %eax
    update_sels_from_ax
    ret

/*
 * Initialise routine.  Load GDT, fix IDT handler references, load IDT, initialise PIC.
 */
init:
    pusha

    //load IDT
    movl $gdt_end_descriptor, %eax
    lgdt (%eax)
    jmp $0x08, $_here
_here:
    movw $0x10, %ax
    update_sels_from_ax

    //Fix IDT handler pointers
    movl $idt_gates_start, %ebx
    loop:
        movl (%ebx), %edx//Get full 32 bit handler pointer
        movw $0x08, 2(%ebx)//Put 16 bit kernel selector where high bits of pointer were
        shrl $16, %edx//Shift the handler pointer to get high bits
        movw %dx, 6(%ebx)//Put the high bits where they belong (last 2 bytes)
        addl $8, %ebx//Move to next IDT entry
        cmp idt_end-4, %ebx//If we're now beyond the last entry, stop.
        jg loop

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

    sti
    popa
    ret
