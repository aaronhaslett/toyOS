#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS_DOWN 8
int cursor_track = 20;
char us_keyboard[0x39] = {0, 0, '1','2','3','4','5','6','7','8','9','0','-','+',0,0,
                          'q','w','e','r','t','y','u','i','o','p','[',']',0,0,
                          'a','s','d','f','g','h','j','k','l',';','\'',0,0,
                          0,'z','x','c','v','b','n','m',',','.','/',0,'*',0,0};
uint8_t active_keys[MAX_KEYS_DOWN];
uint8_t num_keys_down = 0;

uint16_t* t_buf = (uint16_t*) 0xB8000;
void kernel_main(void){
    __asm__ __volatile__("int $4");
    t_buf[0] = 'A' | 12 << 8;
    t_buf[1] = 'A' | 12 << 8;
    t_buf[2] = 'A' | 12 << 8;
    active_keys[0] = 4;

    while(true){}
}

void handle_key(uint8_t scancode){
    if(num_keys_down >= MAX_KEYS_DOWN) return;

    bool down_key = scancode <= 0x39;
    if(!down_key){
       if(scancode < 0x80) return;
       scancode -= 0x80;
    }

    for(int i = 0; i < num_keys_down; i++){
        if(active_keys[i] == scancode){
            if(!down_key)
                active_keys[i] = active_keys[--num_keys_down];
            return;
        }
    }
    if(down_key)
        active_keys[num_keys_down++] = scancode;
    return;
}

void root_handler(uint32_t callret, uint32_t eax, uint32_t int_num, uint32_t int_info){
    t_buf[10] = (int_num+48) | (0xf4 << 8);
    t_buf[11] = (int_info+48) | (0xf4 << 8);
    if(int_num == 33){//keyboard interrupt
        handle_key(int_info);
        if(int_info <= 0x39){
            t_buf[cursor_track++] = us_keyboard[int_info] | (0xf4 << 8);}
    }
}
