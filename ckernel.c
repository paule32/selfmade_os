void k_clear_screen()
{
    char* vidmem = (char*) 0xb8000;
    unsigned int i=0;
    while(i<(80*2*25))
    {
        vidmem[i] = ' ';
        ++i;
        vidmem[i] = 0x07;
        ++i;
    }
}

unsigned int k_printf(char* message, unsigned int line)
{
    char* vidmem = (char*) 0xb8000;
    unsigned int i = line*80*2;

    while(*message!=0)
    {
        if(*message==0x2F)
        {
            *message++;
            if(*message==0x6e)
            {
                line++;
                i=(line*80*2);
                *message++;
                if(*message==0){return(1);};
            }
        }
        vidmem[i]=*message;
        *message++;
        ++i;
        vidmem[i]=0x7;
        ++i;
    }
    return 1;
}

void outportb(unsigned int port,unsigned char value)
{
    asm volatile ("outb %%al,%%dx"::"d" (port), "a" (value));
}

void update_cursor(int row, int col)
{
    unsigned short    position=(row*80) + col;
    // cursor LOW port to vga INDEX register
    outportb(0x3D4, 0x0F);
    outportb(0x3D5, (unsigned char)(position&0xFF));
    // cursor HIGH port to vga INDEX register
    outportb(0x3D4, 0x0E);
    outportb(0x3D5, (unsigned char)((position>>8)&0xFF));
}

int main()
{
    k_clear_screen();
    k_printf("Welcome to MyOS.", 0);
    k_printf("The C kernel has been loaded.", 2);
    update_cursor(3, 0);
    return 0;
}
