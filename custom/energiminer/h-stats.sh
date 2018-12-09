#!/bin/bash

. $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

if [[ -z $CUSTOM_LOG_BASENAME ]]; then
    LOG="energiminer.log"
else
    LOG="$CUSTOM_LOG_BASENAME.log"
fi

local stats_raw=`cat ${LOG} | tail -n 100 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | grep -w "energiminer" | tail -n 1 | grep "^ m "`

#Calculate miner log freshness
local maxDelay=120
local time_now=`date +%T | awk -F: '{ print ($1 * 3600) + $2*60 + $3 }'`
local time_rep=`echo $stats_raw | sed 's/^.*\<Time\>: //' | awk -F: '{ print ($1 * 3600) + $2*60}'`
local diffTime=`echo $((time_now-time_rep)) | tr -d '-'`

if [ "$diffTime" -lt "$maxDelay" ]; then
	# Total reported hashrate MHs
	local total_hashrate=$((grep "Speed" | awk '{ print $5 }') <<< $stats_raw)

	# Hashrate, temp, fans per card
	local cards=`echo "$stats_raw" | sed 's/^.*Mh\/s[[:space:]]*//' | sed 's/GPU\//#/g' | cut -f1 -d '[' | cut -c 2- | tr '#' '\n'`
	local hashrate='[]'
	local temp='[]'
	local fan='[]'

	while read -s line; do
		local gpu_h=`echo $line | awk '{ print $2 }'`
		local gpu_t=`echo $line | awk '{ print $3 }' | cut -c -2`
		local gpu_f=`echo $line | awk '{ print $4 }' | cut -c -2`
		local hashrate=`jq --null-input --argjson hashrate "$hashrate" --argjson gpu_h "$gpu_h" '$hashrate + [$gpu_h]'`
		local temp=`jq --null-input --argjson temp "$temp" --argjson gpu_t "$gpu_t" '$temp + [$gpu_t]'`
		local fan=`jq --null-input --argjson fan "$fan" --argjson gpu_f "$gpu_f" '$fan + [$gpu_f]'`
	done <<< "$cards"

	# Miner uptime
	local uptime=`echo "$stats_raw" | sed -e 's/^.*\<Time\>\://g' | awk -F: '{ print ($1 * 3600) + $2*60 }'`
	# A/R
	eval `echo "$stats_raw" | cut -f 2 -d '[' | cut -f 1 -d ']' | tr -d ',' | sed 's/^A/acc=/g' | sed 's/R/rej=/g' | tr ':' ' '`
	[[ -z $acc ]] && acc=0
	[[ -z $rej ]] && rej=0

	[[ -z $CUSTOM_VERSION ]] && CUSTOM_VERSION="2.2.1"
	stats=$(jq -nc  \
			--argjson hs "$hashrate" \
			--argjson temp "$temp" \
			--argjson fan "$fan" \
			--arg uptime "`echo $uptime`" \
			--arg acc "$acc" \
			--arg rej "$rej" \
			--arg ver "$CUSTOM_VERSION" \
			'{ hs: $hs, hs_units: "mhs", temp: $temp, fan: $fan, uptime: $uptime, ar: [$acc, $rej], algo: "energihash", ver: $ver }')

	# total hashrate: miner reports in mhs, so convert to khs
	khs=`echo $total_hashrate | awk '{ printf($1*1000) }'`
else
	khs=0
	stats="null"
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"

# DEBUG output
#echo $stats | jq -c -M '.'
#echo $khs

