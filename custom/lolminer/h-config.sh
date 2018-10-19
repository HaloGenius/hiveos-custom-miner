#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[ -t 1 ] && . colors
#. h-manifest.conf

[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_PASS ]] && CUSTOM_PASS="x"


pools='[]'
for url in $CUSTOM_URL; do
	pool_url=`echo $url | tr ":" "\n" | head -n 1`
	pool_port=`echo $url | tr ":" "\n" | tail -n 1`
	pool=$(cat <<EOF
	{"POOL": "$pool_url", "PORT": "$pool_port", "USER": "$CUSTOM_TEMPLATE", "PASS": "$CUSTOM_PASS" }
EOF
)
	pools=`jq --null-input --argjson pools "$pools" --argjson pool "$pool" '$pools + [$pool]'`
done

# Failover servers
conf=`jq --argfile f1 ${CUSTOM_TPL_CONFIG} --argjson f2 "$pools" -n '$f1 | .HIVEOS.POOLS = $f2'`

# User defined configuration
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
	while read -r line; do
			[[ -z $line ]] && continue
			conf=`jq -n --argjson conf "$conf" --argjson line "{$line}" '$conf * {HIVEOS: $line}'`
	done <<< "$CUSTOM_USER_CONFIG"
fi

#conf=$(sed "s/%CUSTOM_USER_CONFIG%/$CUSTOM_USER_CONFIG/g" <<< "$conf")
conf=$(sed "s/%USER_TEMPLATE%/$CUSTOM_USER_TEMPLATE/g" <<< "$conf")
conf=$(sed "s/%POOL_URL%/$pool_url/g" <<< "$conf")
conf=$(sed "s/%POOL_PORT%/$pool_port/g" <<< "$conf")
conf=$(sed "s/%POOL_PASS%/$CUSTOM_PASS/g" <<< "$conf")

#replace tpl values in whole file
[[ -z $EWAL && -z $ZWAL && -z $DWAL ]] && echo -e "${RED}No WAL address is set${NOCOLOR}"
[[ ! -z $EWAL ]] && conf=$(sed "s/%EWAL%/$EWAL/g" <<< "$conf") #|| echo "${RED}EWAL not set${NOCOLOR}"
[[ ! -z $DWAL ]] && conf=$(sed "s/%DWAL%/$DWAL/g" <<< "$conf") #|| echo "${RED}DWAL not set${NOCOLOR}"
[[ ! -z $ZWAL ]] && conf=$(sed "s/%ZWAL%/$ZWAL/g" <<< "$conf") #|| echo "${RED}ZWAL not set${NOCOLOR}"
[[ ! -z $EMAIL ]] && conf=$(sed "s/%EMAIL%/$EMAIL/g" <<< "$conf")
[[ ! -z $WORKER_NAME ]] && conf=$(sed "s/%WORKER_NAME%/$WORKER_NAME/g" <<< "$conf") #|| echo "${RED}WORKER_NAME not set${NOCOLOR}"

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1
echo "$conf" > $CUSTOM_CONFIG_FILENAME

