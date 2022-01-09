#!/bin/bash

if [ -f asp ]
then
	:
else
	make;
fi

if [ -f athrill_mmap.bin ]
then
	:
else
	dd if=/dev/zero of=athrill_mmap.bin bs=1k count=8
fi
if [ -f unity_mmap.bin ]
then
	:
else
	dd if=/dev/zero of=unity_mmap.bin bs=1k count=8
fi

athrill2 -c1 -t -1 -m memory_mmap.txt -d device_config_mmap.txt asp 
