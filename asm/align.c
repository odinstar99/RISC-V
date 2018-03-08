#define LEDS ((volatile unsigned int *) 0x70000000)
#define HEX ((volatile unsigned int *) 0x70000004)
#define SWITCH ((volatile unsigned int *) 0x70000008)

unsigned int last_switch_state;

void wait_for_change() {
    unsigned int read_switch;
    while ((read_switch = *SWITCH) == last_switch_state) {
        for (int i = 0; i < 100000; i++) asm volatile ("nop");
    }
    last_switch_state = read_switch;
}

unsigned char data[] = {0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef};

void main() {
    last_switch_state = *SWITCH;

    *HEX = data[0];
    wait_for_change();
    *HEX = data[1];
    wait_for_change();
    *HEX = data[2];
    wait_for_change();
    *HEX = data[3];
    wait_for_change();
    *HEX = data[4];
    wait_for_change();
    *HEX = data[5];
    wait_for_change();
    *HEX = data[6];
    wait_for_change();
    *HEX = data[7];
    wait_for_change();

    *HEX = *((unsigned short *) (data + 0));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 1));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 2));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 3));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 4));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 5));
    wait_for_change();
    *HEX = *((unsigned short *) (data + 6));
    wait_for_change();

    *HEX = *((unsigned int *) (data + 0));
    wait_for_change();
    *HEX = *((unsigned int *) (data + 1));
    wait_for_change();
    *HEX = *((unsigned int *) (data + 2));
    wait_for_change();
    *HEX = *((unsigned int *) (data + 3));
    wait_for_change();
    *HEX = *((unsigned int *) (data + 4));
    wait_for_change();

    *HEX = 0x888888;
}
