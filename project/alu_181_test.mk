PROJ := alu_181_test
ALL_PROJECTS += $(PROJ)

PROJECT_$(PROJ)_SRC := src/alu_181_test.v src/alu_181.v
PROJECT_$(PROJ)_BUILDDIR := $(call TOBUILDDIR,$(PROJ))
PROJECT_$(PROJ)_TARGET := $(PROJECT_$(PROJ)_BUILDDIR)/Vtestbench

PROJ :=

