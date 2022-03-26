#
# Makefile for a workspace of EV3 Platform(ASP3).
#

#
# Include configurations of EV3RT(ASP3) SDK
#
SDKDIR = ..
WSPDIR = $(basename $(PWD))
ASPMAKEFILE = Makefile.asp
include ../common/Makefile.workspace

ifeq ($(APPLDIR),)
APPLDIR = $(shell cat appdir)
include $(APPLDIR)/Makefile.inc
endif

start: appdir
	$(ADDITIONAL_PRE_APPL)
	sudo env LD_PRELOAD=../common/setjmp/libssetjmp.so ./asp -d ../common/device_config.txt

startsim: appdir
	$(ADDITIONAL_PRE_APPL)
	sudo env LD_PRELOAD=../common/setjmp/libssetjmp.so ./asp -d ../common/device_config_athrill.txt

debug: appdir
	$(ADDITIONAL_PRE_APPL)
	gdb asp
appdir:
	@echo "make asp first!"
