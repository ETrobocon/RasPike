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
	#athrill2 -c1 -m $(APLDIR)/memory.txt -d $(APLDIR)/device_config.txt -t -1 asp
	$(ADDITIONAL_PRE_APPL)
	athrill2 -c1 -m ../common/memory.txt -d ../common/device_config.txt -t -1 asp

debug: appdir
	$(ADDITIONAL_PRE_APPL)
	athrill2 -c1 -i -m ../common/memory.txt -d ../common/device_config.txt -t -1 asp
appdir:
	@echo "make asp first!"
