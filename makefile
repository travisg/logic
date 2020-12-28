# build dir that everything goes under
BUILDDIR := build
TOBUILDDIR = $(addprefix $(BUILDDIR)/,$(1))

# start off with an empty list of projects
ALL_PROJECTS :=

# find all the projects
include $(wildcard project/*.mk)

#$(info ALL_PROJECTS = $(sort $(ALL_PROJECTS)))

list:
	@echo 'List of all buildable projects: (look in project/ directory)'; \
	for p in $(sort $(ALL_PROJECTS)); do \
		echo $$p; \
	done; \
	echo 'Hint: build all of the main projects with the "all" target'

all::

# stamped out once per project
define project
$(info stamping out rules for project $(1))
$(PROJECT_$(1)_TARGET): $(PROJECT_$(1)_SRC) testbench.cpp
	@mkdir -p $$(dir $$@)
	verilator -Wno-fatal --top-module testbench --Mdir $$(dir $$@) -Iice-chips-verilog/source-7400 --exe $$(realpath testbench.cpp) --cc -CFLAGS "-DTRACE=1" --trace $$(PROJECT_$(1)_SRC)
	make -C $$(dir $$@) -f Vtestbench.mk

$(info generating rule for $(1) (real target at $(PROJECT_$(1)_TARGET)))
.PHONY: $(1)
$(1): $(PROJECT_$(1)_TARGET)

# add this to the all list
all:: $(1)

$(info generating rule for $(1)-vcd)
.PHONY: $(1)-vcd
$(1)-vcd: $(PROJECT_$(1)_TARGET)
	cd $$(PROJECT_$(1)_BUILDDIR); \
	./Vtestbench -c 500

$(info generating rule for $(1)-wave)
.PHONY: $(1)-wave
$(1)-wave: $(1)-vcd
	gtkwave $$(PROJECT_$(1)_BUILDDIR)/trace.vcd

endef

# stamp out rules per project
$(foreach p,$(ALL_PROJECTS),$(eval $(call project,$p)))

.PHONY: all list clean

clean::
	rm -f -- $(EXTRADEPS)
	rm -rf -- $(BUILDDIR)
