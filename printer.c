int cursor_track = 5;
uint16_t* t_buf = (uint16_t*) 0xB8000;

//^ every 8 bytes                ^       ^       ^       ^       ^       ^       ^
char us_keyboard[0x39] = "  1234567890-+  qwertyuiop[]  asdfghjkl;'   zxcvbnm,./  ";

#define MAX_KEYS_DOWN 8
uint8_t active_keys[MAX_KEYS_DOWN];
uint8_t num_keys_down = 0;

void print_c(char c){
    if(c == '\n')
        cursor_track += (80 - (cursor_track % 80));
    else
        t_buf[cursor_track++] = c | (0xf4 << 8);
}

void print_s(const char* str){
    for(char c = *str; c != '\0'; c = *(++str))
        print_c(c);
}

void print_i_rec(uint32_t num){
    if(num == 0) return;
    uint32_t div = num % 10;
    print_i_rec((num - div) / 10);
    print_c((char)(div + 48));
}

void print_i(uint32_t num){
    if(num == 0)
        print_c('0');
    else
        print_i_rec(num);
}

void print_x(uint32_t num){
    uint32_t p;
    int i;
    print_s("0x");
    for(i = 28; num >> i == 0; i-=4);;
    for(; i >= 0; i-=4){
        p = num >> i;
        num -= (p << i);
        if(p < 10)
            print_c(p + 48);
        else
            print_c(p + 87);
    }
}

void print_b(int num){
    int p;
    for(int i = 31; i >= 0; i--){
        p = num >> i;
        num -= (p << i);
        print_c(p + 48);
    }
}

void printf(const char* format, ...){
    va_list params;
    va_start(params, format);
    char c;

    for(c = *format; c != '\0'; c = *(++format)){
        if(c == '%'){
            c = *(++format);
            if(c == 'c')
                print_c((char) va_arg(params, int));
            else if(c == 's')
                print_s((const char*) va_arg(params, const char*));
            else if(c == 'u')
                print_i((uint32_t) va_arg(params, uint32_t));
            else if(c == 'x')
                print_x((uint32_t) va_arg(params, uint32_t));
            else if(c == 'b')
                print_b((int) va_arg(params, int));
        }else{
            print_c(c);
        }
    }

    va_end(params);
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
    if(down_key){
        active_keys[num_keys_down++] = scancode;

        if(scancode <= 0x39)
            print_c(us_keyboard[scancode]);
    }
    return;
}
