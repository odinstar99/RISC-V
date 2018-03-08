#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define HEX ((volatile unsigned int *) 0x70000008)
#define SWITCH ((volatile unsigned int *) 0x70000010)

unsigned int lw(unsigned char *addr) {
    unsigned int result;
    asm volatile ("lw %0, 0(%1)" : "=r"(result) : "r"(addr), "m"(*addr));
    return result;
}

void sw(unsigned char *addr, unsigned int value) {
    asm volatile ("sw %0, 0(%1)" : : "r"(value), "r"(addr) : "memory");
}

unsigned short lhu(unsigned char *addr) {
    unsigned short result;
    asm volatile ("lhu %0, 0(%1)" : "=r"(result) : "r"(addr), "m"(*addr));
    return result;
}

void sh(unsigned char *addr, unsigned int value) {
    asm volatile ("sh %0, 0(%1)" : : "r"(value), "r"(addr) : "memory");
}

void compare_byte(unsigned char a, unsigned char b, unsigned int line) {
    if (a != b) {
        *HEX = (0xff << 16) | line;
        while (1);
    }
    if (*SWITCH) {
        *HEX = line;
        for (int i = 0; i < 5000000; i++) asm volatile ("nop");
    }
}

void compare_halfword(unsigned short a, unsigned short b, unsigned int line) {
    if (a != b) {
        *HEX = (0xff << 16) | line;
        while (1);
    }
    if (*SWITCH) {
        *HEX = line;
        for (int i = 0; i < 5000000; i++) asm volatile ("nop");
    }
}

void compare_word(unsigned int a, unsigned int b, unsigned int line) {
    if (a != b) {
        *HEX = (0xff << 16) | line;
        while (1);
    }
    if (*SWITCH) {
        *HEX = line;
        for (int i = 0; i < 5000000; i++) asm volatile ("nop");
    }
}

unsigned char data[] = {0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef};
unsigned char empty[8] = {0};

void main() {
    *CONFIG |= 2; // Enable 7-segment display

    compare_byte(data[0], 0x12, __LINE__);
    compare_byte(data[1], 0x34, __LINE__);
    compare_byte(data[2], 0x56, __LINE__);
    compare_byte(data[3], 0x78, __LINE__);
    compare_byte(data[4], 0x90, __LINE__);
    compare_byte(data[5], 0xab, __LINE__);
    compare_byte(data[6], 0xcd, __LINE__);
    compare_byte(data[7], 0xef, __LINE__);

    compare_halfword(lhu(data + 0), 0x3412, __LINE__);
    compare_halfword(lhu(data + 1), 0x5634, __LINE__);
    compare_halfword(lhu(data + 2), 0x7856, __LINE__);
    compare_halfword(lhu(data + 3), 0x9078, __LINE__);
    compare_halfword(lhu(data + 4), 0xab90, __LINE__);
    compare_halfword(lhu(data + 5), 0xcdab, __LINE__);
    compare_halfword(lhu(data + 6), 0xefcd, __LINE__);

    compare_word(lw(data + 0), 0x78563412, __LINE__);
    compare_word(lw(data + 1), 0x90785634, __LINE__);
    compare_word(lw(data + 2), 0xab907856, __LINE__);
    compare_word(lw(data + 3), 0xcdab9078, __LINE__);
    compare_word(lw(data + 4), 0xefcdab90, __LINE__);

    unsigned int *empty_ptr = (unsigned int *) empty;
    sw(empty + 0, 0x12345678);
    compare_word(empty_ptr[0], 0x12345678, __LINE__);
    compare_word(empty_ptr[1], 0x00000000, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sw(empty + 1, 0x12345678);
    compare_word(empty_ptr[0], 0x34567800, __LINE__);
    compare_word(empty_ptr[1], 0x00000012, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sw(empty + 2, 0x12345678);
    compare_word(empty_ptr[0], 0x56780000, __LINE__);
    compare_word(empty_ptr[1], 0x00001234, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sw(empty + 3, 0x12345678);
    compare_word(empty_ptr[0], 0x78000000, __LINE__);
    compare_word(empty_ptr[1], 0x00123456, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sw(empty + 4, 0x12345678);
    compare_word(empty_ptr[0], 0X00000000, __LINE__);
    compare_word(empty_ptr[1], 0x12345678, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 0, 0x1234);
    compare_word(empty_ptr[0], 0X00001234, __LINE__);
    compare_word(empty_ptr[1], 0x00000000, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 1, 0x1234);
    compare_word(empty_ptr[0], 0X00123400, __LINE__);
    compare_word(empty_ptr[1], 0x00000000, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 2, 0x1234);
    compare_word(empty_ptr[0], 0X12340000, __LINE__);
    compare_word(empty_ptr[1], 0x00000000, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 3, 0x1234);
    compare_word(empty_ptr[0], 0X34000000, __LINE__);
    compare_word(empty_ptr[1], 0x00000012, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 4, 0x1234);
    compare_word(empty_ptr[0], 0X00000000, __LINE__);
    compare_word(empty_ptr[1], 0x00001234, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 5, 0x1234);
    compare_word(empty_ptr[0], 0X00000000, __LINE__);
    compare_word(empty_ptr[1], 0x00123400, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    sh(empty + 6, 0x1234);
    compare_word(empty_ptr[0], 0X00000000, __LINE__);
    compare_word(empty_ptr[1], 0x12340000, __LINE__);
    empty_ptr[0] = 0; empty_ptr[1] = 0;

    *CONFIG |= 4; // Enable segment mode
    *HEX = 0x5e5c5479;
}
