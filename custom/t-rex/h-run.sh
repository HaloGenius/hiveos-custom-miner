#!/usr/bin/env bash

cd `dirname $0`

[ -t 1 ] && . colors

. h-manifest.conf

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No $CUSTOM_CONFIG_FILENAME is found${NOCOLOR}" && return 2
[[ ! -s $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Config file is empty - check syntax! ${NOCOLOR}" && return 3

DRV_VERS=`nvidia-smi --help | head -n 1 | awk '{print $NF}' | sed 's/v//' | tr '.' ' ' | awk '{print $1}'`

#echo $DRV_VERS

echo -e -n "${GREEN}NVidia${NOCOLOR} driver ${GREEN}${DRV_VERS}${NOCOLOR}-series detected "
if [ ${DRV_VERS} -ge 410 ]; then
    echo -e "(${BCYAN}CUDA 10${NOCOLOR} compatible)"
    binary=t-rex-c100
elif [ ${DRV_VERS} -ge 396 ]; then
    echo -e "(${BCYAN}CUDA 9.2${NOCOLOR} compatible)"
    binary=t-rex-c92
else
    echo -e "(${BCYAN}CUDA 9.1${NOCOLOR} compatible)"
    binary=t-rex-c91
fi

./${binary} -c ${CUSTOM_CONFIG_FILENAME}
#./t-rex -c config.json
