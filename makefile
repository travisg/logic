BUILD := build
TESTBENCH := $(BUILD)/Vtestbench
SIMULATOR := $(BUILD)/Vsim

SRC := \

#cpu.v \
#memory.v \
#regfile.v

TEST_SRC = testbench.v
SIM_SRC = sim.v dpi_memory.v

EXTRADEPS := test.hex

all:: $(TESTBENCH)

$(TESTBENCH): $(TEST_SRC) $(SRC) testbench.cpp makefile
	mkdir -p $(dir $@)
	verilator -Wno-fatal --top-module testbench --Mdir $(dir $@) -Icpu --exe testbench.cpp --cc -CFLAGS "-DTRACE=1" --trace $(TEST_SRC) $(SRC)
	make -C $(dir $@) -f Vtestbench.mk

#all:: $(SIMULATOR)
$(SIMULATOR): $(SIM_SRC) $(SRC) sim.cpp makefile
	mkdir -p $(dir $@)
	verilator -Wno-fatal --top-module sim --Mdir $(dir $@) -Icpu --exe sim.cpp --cc -CFLAGS "-DSIMULATION -DTRACE=0" --trace $(SIM_SRC) $(SRC)
	make -C $(dir $@) -f Vsim.mk

.PHONY: vcd wave sim test.hex makefile

sim: $(SIMULATOR) test.hex
	./$(SIMULATOR) -i test.hex -c 500 -t -o test.bin

vcd: $(TESTBENCH)
	cd $(BUILD); \
	./Vtestbench -c 100

wave: vcd
	gtkwave $(BUILD)/trace.vcd

clean::
	rm -f -- $(EXTRADEPS)
	rm -rf -- $(BUILD)
