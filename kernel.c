#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

char us_keyboard[0x36] = {' ', ' ', '1','2','3','4','5','6','7','8','9','0','-','+',' ',' ',//16
                          'q','w','e','r','t','y','u','i','o','p','[',']',' ',' ',//14
                          'a','s','d','f','g','h','j','k','l',';','\'',' ',' ',//13
                          ' ','z','x','c','v','b','n','m',',','.','/'};//11
//int wtf[100];
#define MAX_KEYS_DOWN 8
uint8_t active_keys[MAX_KEYS_DOWN];
uint8_t num_keys_down = 0;
int cursor_track = 5;

uint16_t* t_buf = (uint16_t*) 0xB8000;
void kernel_main(void){
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
    t_buf[1] = (int_num+48) | (0xf4 << 8);
    t_buf[2] = (int_info+48) | (0xf4 << 8);
    if(int_num == 33){//keyboard interrupt
        handle_key(int_info);
        if(int_info <= 0x39){
            t_buf[cursor_track++] = us_keyboard[int_info] | (0xf4 << 8);} //Write key to screen.
    }
}
