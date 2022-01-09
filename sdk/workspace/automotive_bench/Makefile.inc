mkfile_path := $(dir $(lastword $(MAKEFILE_LIST)))

APPL_COBJS += basicmath_small.o  rad2deg.o cubic.o isqrt.o
APPL_DIRS += $(mkfile_path)basicmath
APPL_LIBS += -lm

INCLUDES += -I$(mkfile_path)basicmath

