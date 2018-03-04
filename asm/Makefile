CROSS=/Users/michiel/cross/riscv

LIBGCC=$(CROSS)/lib/gcc/riscv-none-embed/7.2.0/rv32i/ilp32/libgcc.a

AS=$(CROSS)/bin/riscv-none-embed-as
GCC=$(CROSS)/bin/riscv-none-embed-gcc
LD=$(CROSS)/bin/riscv-none-embed-ld
OBJDUMP=$(CROSS)/bin/riscv-none-embed-objdump
OBJCOPY=$(CROSS)/bin/riscv-none-embed-objcopy
READELF=$(CROSS)/bin/riscv-none-embed-readelf

GCC_OPT=-march=rv32i -mabi=ilp32 -O2
AS_OPT=-march=rv32i
LD_OPT=-march=rv32i -m elf32lriscv
LD_SCRIPT=linker.ld

all: image.rom fib.rom

.PRECIOUS: image.elf fib.elf

%.o: %.c
	$(GCC) $(GCC_OPT) -c $< -o $@

%.o: %.s
	$(AS) $(AS_OPT) -o $@ $<

%.elf: %.o start.o $(LIBGCC) $(LD_SCRIPT)
	$(LD) $(LD_OPT) -T $(LD_SCRIPT) -o $@ start.o $< $(LIBGCC)

%.rom: %.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -f *.o *.elf *.rom
