ENTRY(_start)

SECTIONS
{
    . = high_half_base + 0x100000;

    .text ALIGN(4K) : AT(ADDR(.text)-high_half_base){
        *(.multiboot)
        *(.text)
    }
    .rodata ALIGN(4K) : AT(ADDR(.rodata)-high_half_base){
        *(.rodata)
    }
    .data ALIGN(4K) : AT(ADDR(.data)-high_half_base){
        *(.data)
    }
    .bss ALIGN(4K) : AT(ADDR(.bss)-high_half_base){
        *(COMMON)
        *(.bss)
    }
}

