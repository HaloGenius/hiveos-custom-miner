#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[ -t 1 ] && . colors
#. h-manifest.conf

#[[ -z $CUSTOM_ALGO ]] && echo -e "${YELLOW}CUSTOM_ALGO is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_PASS ]] && CUSTOM_PASS="x"

pools='[]'
for url in $CUSTOM_URL; do
	pool=$(cat <<EOF
			{"user": "$CUSTOM_TEMPLATE", "url": "$url", "pass": "$CUSTOM_PASS" }
EOF
)
	pools=`jq --null-input --argjson pools "$pools" --argjson pool "$pool" '$pools + [$pool]'`
done
conf=`jq --argfile f1 $CUSTOM_TPL_CONFIG --argjson f2 "$pools" --arg algo "$CUSTOM_ALGO" -n '$f1 | .pools = $f2 | .algo = $algo'`

# User defined configuration
if [[ ! -z $CUSTOM_USER_CONFIG ]]; then
	while read -r line; do
		[[ -z $line ]] && continue
		conf=`jq --null-input --argjson conf "$conf" --argjson line "{$line}" '$conf + $line'`
	done <<< "$CUSTOM_USER_CONFIG"
fi

#replace tpl values in whole file
[[ ! -z $EMAIL ]] && conf=$(sed "s/%EMAIL%/$EMAIL/g" <<< "$conf")
[[ ! -z $WORKER_NAME ]] && conf=$(sed "s/%WORKER_NAME%/$WORKER_NAME/g" <<< "$conf")
notes=`echo Generated at $(date)`
conf=`jq --null-input --argjson conf "$conf" --arg notes "$notes" -n '$conf | ._notes = $notes'`
[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1
echo "$conf" > $CUSTOM_CONFIG_FILENAME
#echo "$conf" > config.json


