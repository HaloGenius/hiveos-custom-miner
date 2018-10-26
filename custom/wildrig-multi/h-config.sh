#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 2
[[ -z $CUSTOM_PASS ]] && CUSTOM_PASS=x

pools=""
for pool_url in $CUSTOM_URL; do
	pools+="--url $pool_url "
done

conf="$pools --user ${CUSTOM_TEMPLATE} --pass ${CUSTOM_PASS} --api-port ${CUSTOM_API_PORT} --print-full --print-time=60 --print-level=2 --donate-level=1"
if [ ! -z $CUSTOM_ALGO ]; then 
	case $CUSTOM_ALGO in
		skunk) wild_algo=skunkhash
			;;
		*)
		wild_algo=$CUSTOM_ALGO
	esac
	conf+=" --algo=${wild_algo}"
fi
[[ ! -z $CUSTOM_USER_CONFIG ]] && conf+=" ${CUSTOM_USER_CONFIG}"

#replace tpl values in whole file
[[ -z $EWAL && -z $ZWAL && -z $DWAL ]] && echo -e "${RED}No WAL address is set${NOCOLOR}"
[[ ! -z $EWAL ]] && conf=$(sed "s/%EWAL%/$EWAL/g" <<< "$conf")
[[ ! -z $DWAL ]] && conf=$(sed "s/%DWAL%/$DWAL/g" <<< "$conf")
[[ ! -z $ZWAL ]] && conf=$(sed "s/%ZWAL%/$ZWAL/g" <<< "$conf")
[[ ! -z $EMAIL ]] && conf=$(sed "s/%EMAIL%/$EMAIL/g" <<< "$conf")
[[ ! -z $WORKER_NAME ]] && conf=$(sed "s/%WORKER_NAME%/$WORKER_NAME/g" <<< "$conf") #|| echo "${RED}WORKER_NAME not set${NOCOLOR}"

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 10

echo "$conf" > $CUSTOM_CONFIG_FILENAME
