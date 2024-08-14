set environment LD_PRELOAD=../common/setjmp/libssetjmp.so
handle SIGUSR2 noprint nostop pass
run -d ../common/device_config_raspike-art.txt
