#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include "printer.c"

void kernel_main(uint32_t k_v_start, uint32_t k_p_start, uint32_t k_size){
    printf("\n\nvirtual start: %x\nphysical start: %x\nsize: %x\n", k_v_start, k_p_start, k_size);
    while(true){}
}

void root_handler(uint32_t int_num, uint32_t int_info){
    t_buf[1] = (int_num+48) | (0xf4 << 8);
    t_buf[2] = (int_info+48) | (0xf4 << 8);
    if(int_num == 33)//keyboard interrupt
        handle_key(int_info);
    return;
}
