#!/bin/bash
#a="/mnt/c/Users/ykomi/cur/athrill/ev3rt-athrill-v850e2m/sdk/workspace"
appdir=$(cat appdir)
common_dir=$(dirname $0)

cat appdir | sed 's/\//\\\//g' > ${common_dir}/fragment_2.sed
cat ${common_dir}/fragment_1.sed ${common_dir}/fragment_2.sed ${common_dir}/fragment_3.sed | tr -d '[:cntrl:]' > ${appdir}/_x.sed

sed -f ${appdir}/_x.sed ${appdir}/memory_mmap.tmpl > ${appdir}/memory_mmap.txt


