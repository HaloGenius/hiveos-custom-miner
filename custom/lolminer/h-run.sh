#!/usr/bin/env bash

cd `dirname $0`

[ -t 1 ] && . colors

. h-manifest.conf

#echo CUSTOM_MINER: $CUSTOM_MINER
#echo CUSTOM_NAME: $CUSTOM_NAME
#echo CUSTOM_LOG_BASENAME: $CUSTOM_LOG_BASENAME
#echo CUSTOM_CONFIG_FILENAME: $CUSTOM_CONFIG_FILENAME

[[ -z $CUSTOM_LOG_BASENAME ]] && echo -e "${RED}No CUSTOM_LOG_BASENAME is set${NOCOLOR}" && exit 1
[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1
CUSTOM_LOG_BASEDIR=`dirname "${CUSTOM_LOG_BASENAME}"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

#echo CUSTOM_LOG_BASEDIR: $CUSTOM_LOG_BASEDIR

PROFILE=HIVEOS
./lolMiner --userCFG ${CUSTOM_CONFIG_FILENAME} --profile ${PROFILE} $@ 2>&1 | tee $CUSTOM_LOG_BASENAME.log
