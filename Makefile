OBJ_DIR=obj_dir
ASM_DIR=asm

VERILATOR=verilator
VERILATOR_FLAGS=-Wall -Wno-fatal -O3 -CFLAGS "-O3 -std=c++11" --trace

ALU_PREFIX=alu
ALU_VPREFIX=V$(ALU_PREFIX)
ALU_TEST=$(OBJ_DIR)/$(ALU_VPREFIX)
ALU_TEST_RTL=rtl/alu.sv
ALU_TEST_SRC=sim/alu_sim.cpp

CORE_PREFIX=core
CORE_VPREFIX=V$(CORE_PREFIX)
CORE_TEST=$(OBJ_DIR)/$(CORE_VPREFIX)
CORE_TEST_RTL=rtl/core.sv rtl/alu.sv rtl/decode.sv rtl/hazard.sv rtl/regfile.sv rtl/types.sv
CORE_TEST_SRC=sim/core_sim.cpp
CORE_TEST_ROM=image.rom

.PHONY: test

all: $(CORE_TEST)

run: $(CORE_TEST) $(ASM_DIR)/$(CORE_TEST_ROM)
	$(CORE_TEST) $(ASM_DIR)/$(CORE_TEST_ROM)

trace: $(CORE_TEST) $(ASM_DIR)/$(CORE_TEST_ROM)
	$(CORE_TEST) $(ASM_DIR)/$(CORE_TEST_ROM) --trace

$(ASM_DIR)/$(CORE_TEST_ROM):
	$(MAKE) -C $(ASM_DIR) $(CORE_TEST_ROM)

test: $(ALU_TEST)
	$(ALU_TEST)

clean:
	rm -rf obj_dir
	$(MAKE) -C asm clean

$(ALU_TEST): $(ALU_TEST_RTL) $(ALU_TEST_SRC)
	$(VERILATOR) $(VERILATOR_FLAGS) -cc $(ALU_TEST_RTL) --exe $(ALU_TEST_SRC)
	$(MAKE) -j -C $(OBJ_DIR) -f $(ALU_VPREFIX).mk

$(CORE_TEST): $(CORE_TEST_RTL) $(CORE_TEST_SRC)
	$(VERILATOR) $(VERILATOR_FLAGS) -cc $(CORE_TEST_RTL) --exe $(CORE_TEST_SRC) -Irtl
	$(MAKE) -j -C $(OBJ_DIR) -f $(CORE_VPREFIX).mk