void print_c(char c){
    t_buf[cursor_track++] = c | (0xf4 << 8);
}

void print_s(const char* str){
    for(char c = *str; c != '\0'; c = *(++str))
        print_c(c);
}

void print_i(int num){
    if(num == 0)
        return;
    int div = num % 10;
    print_i((num - div) / 10);
    print_c((char) div + 48);
}

void print_x(int num){
    int p,i;
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
            else if(c == 'd')
                print_i((int) va_arg(params, int));
            else if(c == 'x')
                print_x((int) va_arg(params, int));
            else if(c == 'b')
                print_b((int) va_arg(params, int));
        }else{
            print_c(c);
        }
    }

    va_end(params);
}


