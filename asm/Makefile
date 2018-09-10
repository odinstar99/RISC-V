CROSS=$(HOME)/cross/riscv

LIBGCC=$(CROSS)/lib/gcc/riscv-none-embed/7.2.0/rv32im/ilp32/libgcc.a
MIFFED=$(HOME)/Development/Rust/miffed/target/release/miffed

AS=$(CROSS)/bin/riscv-none-embed-as
GCC=$(CROSS)/bin/riscv-none-embed-gcc
LD=$(CROSS)/bin/riscv-none-embed-ld
OBJDUMP=$(CROSS)/bin/riscv-none-embed-objdump
OBJCOPY=$(CROSS)/bin/riscv-none-embed-objcopy
READELF=$(CROSS)/bin/riscv-none-embed-readelf

GCC_OPT=-march=rv32im -mabi=ilp32 -O2
AS_OPT=-march=rv32im
LD_OPT=-march=rv32im -m elf32lriscv
LD_SCRIPT=linker.ld

all: image.mif fib.mif background.mif align.mif uart.mif

.PRECIOUS: %.elf %.rom

%.o: %.c
	$(GCC) $(GCC_OPT) -c $< -o $@

%.o: %.s
	$(AS) $(AS_OPT) -o $@ $<

%.elf: %.o start.o $(LIBGCC) $(LD_SCRIPT)
	$(LD) $(LD_OPT) -T $(LD_SCRIPT) -o $@ start.o $< $(LIBGCC)

%.rom: %.elf
	$(OBJCOPY) -O binary $< $@

%.mif: %.rom
	$(MIFFED) $< $@

clean:
	rm -f *.o *.elf *.rom *.mif
