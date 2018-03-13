#define WIDTH   32
#define HEIGHT  32

#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define UART_STATUS ((volatile unsigned int *) 0x70000040)
#define UART_TX ((volatile unsigned int *) 0x70000044)

void uart_putc(char c) {
    while (*UART_STATUS & 1);
    *UART_TX = c;
    *LEDS += 1;
}

char lookup[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
void uart_puthex(char c) {
    uart_putc(lookup[(c >> 4) & 0xf]);
    uart_putc(lookup[c & 0xf]);
}

char buf_i[1024] = {
    0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x10, 0x10, 0x0f,
    0x10, 0x11, 0x0f, 0x0f, 0x10, 0x11, 0x0f, 0x0f, 0x11, 0x11, 0x0f, 0x0f, 0x11, 0x11, 0x10, 0x10, 0x11, 0x12, 0x10, 0x10, 0x12, 0x10, 0x20, 0x39, 0x3a, 0x3b, 0x3f, 0x3c, 0x40, 0x46, 0x51, 0x61,
    0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x11, 0x11, 0x10, 0x10, 0x11, 0x11, 0x10, 0x12, 0x0f, 0x1d, 0x36, 0x3b, 0x3c, 0x3d, 0x3d, 0x3e, 0x44, 0x53, 0x65,
    0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x10, 0x11, 0x10, 0x10, 0x10, 0x11, 0x10, 0x10, 0x11, 0x10, 0x22, 0x36, 0x39, 0x3c, 0x3c, 0x3a, 0x3e, 0x48, 0x58, 0x6a,
    0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x0f, 0x12, 0x0f, 0x1b, 0x36, 0x3b, 0x3b, 0x3e, 0x3c, 0x3e, 0x48, 0x58, 0x6a,
    0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x1c, 0x37, 0x3c, 0x39, 0x3d, 0x3b, 0x40, 0x4a, 0x58, 0x69,
    0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x0e, 0x12, 0x10, 0x18, 0x34, 0x3b, 0x38, 0x3c, 0x3c, 0x40, 0x48, 0x57, 0x69,
    0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x12, 0x0e, 0x1c, 0x38, 0x3d, 0x3a, 0x3e, 0x3e, 0x41, 0x4b, 0x5c, 0x6d,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x12, 0x0e, 0x18, 0x33, 0x3c, 0x3c, 0x3d, 0x3c, 0x3f, 0x48, 0x58, 0x6b,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x12, 0x0e, 0x1a, 0x37, 0x3d, 0x3a, 0x3e, 0x3c, 0x3c, 0x49, 0x5d, 0x6c,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x11, 0x0f, 0x16, 0x33, 0x3d, 0x39, 0x3c, 0x3d, 0x3d, 0x49, 0x59, 0x69,
    0x10, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x12, 0x0f, 0x1a, 0x33, 0x3a, 0x3c, 0x3d, 0x3b, 0x40, 0x4b, 0x5b, 0x6b,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x11, 0x0f, 0x16, 0x31, 0x3d, 0x3b, 0x3d, 0x3b, 0x3e, 0x4a, 0x59, 0x6b,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x0f, 0x12, 0x0e, 0x19, 0x34, 0x3b, 0x3b, 0x3c, 0x3b, 0x43, 0x4e, 0x5d, 0x6d,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0e, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x11, 0x10, 0x14, 0x31, 0x3e, 0x38, 0x3c, 0x3e, 0x3f, 0x49, 0x5b, 0x6c,
    0x10, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x0f, 0x12, 0x0f, 0x19, 0x33, 0x39, 0x3a, 0x3c, 0x3a, 0x42, 0x4c, 0x5c, 0x6c,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0e, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x11, 0x10, 0x14, 0x30, 0x3d, 0x37, 0x3a, 0x3b, 0x40, 0x4b, 0x59, 0x6b,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x12, 0x0f, 0x17, 0x33, 0x3e, 0x3a, 0x3d, 0x3e, 0x41, 0x4c, 0x5d, 0x6b,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x11, 0x0f, 0x13, 0x32, 0x3d, 0x39, 0x3e, 0x3c, 0x3f, 0x4b, 0x57, 0x6c,
    0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x0e, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x12, 0x10, 0x17, 0x30, 0x3b, 0x39, 0x3c, 0x3d, 0x41, 0x4b, 0x5f, 0x6f,
    0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x11, 0x0f, 0x14, 0x2e, 0x3d, 0x39, 0x3a, 0x3d, 0x3f, 0x4b, 0x5c, 0x66,
    0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x12, 0x10, 0x14, 0x32, 0x3e, 0x39, 0x3b, 0x3b, 0x40, 0x4a, 0x56, 0x61,
    0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0e, 0x0f, 0x11, 0x0f, 0x0e, 0x0f, 0x10, 0x10, 0x0f, 0x10, 0x11, 0x11, 0x0f, 0x11, 0x0f, 0x15, 0x30, 0x3c, 0x3b, 0x3b, 0x3c, 0x40, 0x46, 0x52, 0x5e,
    0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x0e, 0x11, 0x10, 0x15, 0x31, 0x3d, 0x39, 0x3e, 0x3c, 0x3f, 0x4a, 0x50, 0x5c,
    0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x15, 0x30, 0x3d, 0x37, 0x3c, 0x40, 0x3e, 0x47, 0x52, 0x5b,
    0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x11, 0x10, 0x13, 0x2f, 0x3b, 0x39, 0x3e, 0x3b, 0x42, 0x4a, 0x51, 0x61,
    0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x11, 0x0f, 0x15, 0x31, 0x3c, 0x3c, 0x3f, 0x3d, 0x43, 0x47, 0x54, 0x65,
    0x10, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x11, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x14, 0x2f, 0x3c, 0x3a, 0x3c, 0x3d, 0x42, 0x4a, 0x58, 0x69,
    0x0f, 0x10, 0x10, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x0f, 0x11, 0x11, 0x12, 0x2d, 0x3d, 0x3b, 0x3b, 0x3d, 0x43, 0x4d, 0x5c, 0x69,
    0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x10, 0x11, 0x11, 0x13, 0x2c, 0x3e, 0x3b, 0x3c, 0x3e, 0x42, 0x4e, 0x5e, 0x6d,
    0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x10, 0x0e, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x0f, 0x11, 0x10, 0x13, 0x2f, 0x3e, 0x39, 0x3c, 0x3e, 0x40, 0x4e, 0x61, 0x71,
    0x10, 0x10, 0x10, 0x0f, 0x0f, 0x0f, 0x0f, 0x10, 0x0f, 0x10, 0x10, 0x0f, 0x0f, 0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x0f, 0x11, 0x0f, 0x14, 0x2f, 0x3b, 0x3a, 0x3d, 0x3b, 0x42, 0x4e, 0x5e, 0x74,
};
char buf_o[1024] = {0};

void main(void)
{
    int a, b, result;
    int max = 255;

    for (a = 1; a < HEIGHT - 1; a++)
    {
        for (b = 1; b < WIDTH - 1; b++)
        {
            result=((
                         -7*(int)buf_i[(a - 1) * WIDTH + b - 1] +
                          5*(int)buf_i[(a - 1) * WIDTH + b    ] +
                          2*(int)buf_i[(a - 1) * WIDTH + b + 1] +
                         -1*(int)buf_i[ a      * WIDTH + b - 1] +
                         15*(int)buf_i[ a      * WIDTH + b    ] +
                         -1*(int)buf_i[ a      * WIDTH + b + 1] +
                          2*(int)buf_i[(a + 1) * WIDTH + b - 1] +
                          5*(int)buf_i[(a + 1) * WIDTH + b    ] +
                         -7*(int)buf_i[(a + 1) * WIDTH + b + 1] +
                        128) / 13);

            /* Clipping */
            if(result<0) buf_o[a * WIDTH + b] = 0;
            else if (result > 255) buf_o[a * WIDTH + b] = (char)255;
            else buf_o[a * WIDTH + b] = result;
        }
    }

    for (a = 0; a < HEIGHT; a++) {
        for (b = 0; b < WIDTH; b++) {
            uart_puthex(buf_o[a * WIDTH + b]);
        }
        uart_putc('\r');
        uart_putc('\n');
    }
}
