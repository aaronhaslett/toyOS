#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include "printer.c"
#include "multiboot.h"

void kernel_main(uint32_t k_v_start, uint32_t k_p_start, uint32_t k_size, multiboot_info_t *ebx){
    int i=0;
    printf("\n\nvirtual start: %x\nphysical start: %x\nsize: %x\nMB pointer: %x\nMB flags: %x\nMB lower: %x\nMB upper: %x\nMB dump:\n", k_v_start, k_p_start, k_size, ebx->mods_addr->mod_start, ebx->flags, ebx->mem_lower, ebx->mem_upper);
    uint32_t *fake_ebx = (uint32_t*) ebx;
    for(i=0;i<sizeof(multiboot_info_t)/8;i++){
        printf("%x, ", *(fake_ebx+i));
    }
    typedef void (*call_module_t)(void);
    call_module_t sp = (call_module_t)ebx->mods_addr->mod_start;
    sp();
    while(true){}
}

void root_handler(uint32_t int_num, uint32_t int_info){
    t_buf[1] = (int_num+48) | (0xf4 << 8);
    t_buf[2] = (int_info+48) | (0xf4 << 8);
    if(int_num == 33)//keyboard interrupt
        handle_key(int_info);
    return;
}
