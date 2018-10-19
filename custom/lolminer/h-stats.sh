#!/usr/bin/env bash

. /hive/custom/lolminer/h-manifest.conf

#######################
# Functions
#######################

get_amd_cards_temp(){
	echo $(jq -c "[.temp$amd_indexes_array]" <<< $gpu_stats)
}

get_amd_cards_fan(){
	echo $(jq -c "[.fan$amd_indexes_array]" <<< $gpu_stats)
}

#######################
# MAIN script body
#######################
#gpu_stats=`gpu-stats`
stats_raw=`curl --connect-timeout 2 --max-time 5 --silent --noproxy '*' http://127.0.0.1:${API_PORT}/summary`
#echo $stats_raw | jq 
#exit 1
echo $amd_indexes_array | jq

if [[ $? -ne 0 || -z $stats_raw ]]; then
	echo -e "${YELLOW}Failed to read $miner from localhost:${API_PORT}${NOCOLOR}"
else
	khs=`echo $stats_raw | jq -r '.Session.Performance_Summary' | awk '{ print $1/1000 }'`
#	khs=`echo $stats_raw | jq -r '.Session.Performance_Summary'`
	local fan=$(jq -c "[.fan$amd_indexes_array]" <<< $gpu_stats)
	local temp=$(jq -c "[.temp$amd_indexes_array]" <<< $gpu_stats)
	stats=$(jq 	--argjson temp "$temp" \
				--argjson fan "$fan" \
				'{hs: [.GPUs[].Performance], hs_units: "hs", $temp, $fan, uptime: .Session.Uptime, ar: [.Session.Accepted, .Session.Submitted - .Session.Accepted ], algo: .Mining.Algorithm}' <<< "$stats_raw")
fi

	[[ -z $khs ]] && khs=0
	[[ -z $stats ]] && stats="null"

#echo $khs
#echo $stats
