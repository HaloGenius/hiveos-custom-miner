#!/usr/bin/env bash

algo_avail=("lyra2z" "tribus" "phi" "phi2" "c11" "x17")

#######################
# Functions
#######################


get_cards_hashes(){
	# hs is global
	hs=''
	for (( i=0; i < ${GPU_COUNT_NVIDIA}; i++ )); do
		local MHS=`cat $LOG_NAME | tail -n 100 | sed -e "s/\x1b\[.\{1,5\}m//g" | grep "$(echo $i | awk '{printf("GPU #%d^",$1)}')" | tail -n 1 | awk '{printf("%.f\n",$5)}'`
		hs[$i]=`echo $MHS | awk '{ printf("%.f",$1) }'`
	done
}

get_nvidia_cards_temp(){
	echo $(jq -c "[.temp$nvidia_indexes_array]" <<< $gpu_stats)
}

get_nvidia_cards_fan(){
	echo $(jq -c "[.fan$nvidia_indexes_array]" <<< $gpu_stats)
}

get_miner_uptime(){
	local tmp=$(cat $LOG_NAME |  head -n 2 | tail -n 1 | awk '{print $1,$2}')
	local start=$(date +%s -d "${tmp}")
	local now=$(date +%s)
	echo $((now - start))
}

get_miner_algo(){
	local algo=""
	
	for i in "${algo_avail[@]}"
	do
		if [[ ! -z $(echo $CUSTOM_USER_CONFIG | grep $i) ]]; then
			algo=$i
			break
		fi
	done
	echo $algo
}

get_miner_shares_ac(){
	local tmp=$(cat $LOG_NAME | tail -n 100 | sed -e "s/\x1b\[.\{1,5\}m//g" | grep '20[0-9]* [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [[] [A-Z]* []]' | tail -n 1 | awk '{print $6}' | sed 's/[/].*//')
	[[ -z $tmp ]] && echo "0"
	echo $tmp
}

get_miner_shares_rj(){
	local total=$(cat $LOG_NAME | tail -n 100 | sed -e "s/\x1b\[.\{1,5\}m//g" | grep '20[0-9]* [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [[] [A-Z]* []]' | tail -n 1 | awk '{print $6}' | sed -e 's#^[0-9]*[/]##;')
	[[ -z $total ]] && echo "0"
	echo $((total - ac))
}

get_total_hashes(){
	# khs is global
	local tmp=`cat $LOG_NAME | tail -n 100 | sed -e "s/\x1b\[.\{1,5\}m//g" | grep '20[0-9]* [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [[] [A-Z]* []]' | tail -n 1`
	local units=`echo $tmp | awk '{ print $9 }'`
	local Total=0
	case $units in
		kH/s)
			Total=`echo $tmp | awk '{ printf("%.f\n", $8) }'`
		;;
		MH/s)
			Total=`echo $tmp | awk '{ printf("%.f\n", $8*1000) }'`
		;;
		*)
			Total=0
		;;
		
	esac
	echo $Total
}

get_log_time_diff(){
	local tmp=$(cat $LOG_NAME | tail -n 1 | awk '{ print $1,$2}')
	local logTime=`date +%s -d "${tmp}"`
	local curTime=`date +%s`
	echo `expr $curTime - $logTime`
}

#######################
# MAIN script body
#######################

. /hive/custom/$CUSTOM_MINER/h-manifest.conf
local LOG_NAME="$CUSTOM_LOG_BASENAME.log"

[[ -z $GPU_COUNT_NVIDIA ]] &&
	GPU_COUNT_NVIDIA=`gpu-detect NVIDIA`



# Calc log freshness
local diffTime=$(get_log_time_diff)
local maxDelay=120

# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then
	local hs=
	get_cards_hashes					# hashes array
	local hs_units='khs'				# hashes utits
	local temp=$(get_nvidia_cards_temp)	# cards temp
	local fan=$(get_nvidia_cards_fan)	# cards fan
	local uptime=$(get_miner_uptime)	# miner uptime
	local algo=$(get_miner_algo)		# algo

	# A/R shares by pool
	local ac=$(get_miner_shares_ac)
	local rj=$(get_miner_shares_rj)
#	echo ac: $ac
#	echo rj: $rj

	# make JSON
	stats=$(jq -nc \
				--argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
				--arg hs_units "$hs_units" \
				--argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg uptime "$uptime" \
				--arg ac $ac --arg rj "$rj" \
				--arg algo "$algo" \
				'{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $algo}')
	# total hashrate in khs
	khs=$(get_total_hashes)
else
	stats=""
	khs=0
fi

# debug output
##echo temp:  $temp
##echo fan:   $fan
#echo stats: $stats
#echo khs:   $khs
#echo diff: $diffTime
#echo uptime: $uptime