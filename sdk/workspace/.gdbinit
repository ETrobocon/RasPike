set environment LD_PRELOAD=../common/setjmp/aarch64/libssetjmp.so
#set environment LD_LIBRARY_PATH=../common/setjmp/aarch64
handle SIGUSR2 noprint nostop pass
handle SIGSEGV print stop nopass
#handle SIGBUS print stop nopass
#b main
#watch *0x55556ad140
#b act_tsk
run -d ../common/device_config_raspike-art.txt
