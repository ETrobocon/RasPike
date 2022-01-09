#!/bin/bash
common_dir=$(dirname $0)
appdir=$(cat appdir)

if [ -f asp ]
then
	:
else
	make;
fi

if [ -f ${common_dir}/athrill_mmap.bin ]
then
	:
else
	dd if=/dev/zero of=${appdir}/athrill_mmap.bin bs=1k count=8
fi
if [ -f unity_mmap.bin ]
then
	:
else
	dd if=/dev/zero of=${appdir}/unity_mmap.bin bs=1k count=8
fi

${common_dir}/make_memory_text.sh
athrill2 -c1 -t -1 -m ${appdir}/memory_mmap.txt -d ${appdir}/device_config_mmap.txt asp 
