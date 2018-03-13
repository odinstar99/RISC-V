#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define UART_STATUS ((volatile unsigned int *) 0x70000040)
#define UART_TX ((volatile unsigned int *) 0x70000044)

void uart_putc(char c) {
    while (*UART_STATUS & 1);
    *UART_TX = c;
    *LEDS += 1;
}

void uart_puts(char *str) {
    char c;
    while (c = *str++) {
        uart_putc(c);
    }
    uart_putc('\r');
    uart_putc('\n');
}

void main() {
    *CONFIG |= 1;
    uart_putc('H');
    uart_putc('I');
    uart_putc('\r');
    uart_putc('\n');
    while (1) {
        uart_puts("Hello world!");
        for (int i = 0; i < 10000000; i++) asm volatile ("nop");
    }
}
