# for mruby
APPL_LIBS += /root/workspace/mruby/libmruby.a -lm
INCLUDES += -I/root/tools/mruby-2.0.1/include/

APPL_ASMOBJS :=
ifdef USE_CXX
	APPL_CXXOBJS += 
	APPL_COBJS +=
else
	APPL_COBJS += 
endif


