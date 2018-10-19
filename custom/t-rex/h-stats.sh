#!/usr/bin/env bash

cd `dirname $0`
#. h-manifest.conf
#. debug.conf
#. /hive-config/wallet.conf
. /hive/custom/$CUSTOM_MINER/h-manifest.conf

#API_PORT=4058
#API_TIMEOUT=5
algo_avail=("balloon" "bcd" "bitcore" "c11" "hmq1725" "hsr" "lyra2z" "phi" "polytimos" "renesis" "skunk" "sonoa" "tribus" "x16r" "x16s" "x17")

#######################
# Functions
#######################


get_cards_hashes(){
	# hs is global
	for (( i=0; i < ${GPU_COUNT_NVIDIA}; i++ )); do
		hs[$i]=0
	done
	local gpu_total=$(echo $miner_stat | jq ".gpu_total")
	for (( i=0; i < ${gpu_total}; i++ )); do
		local gpu_id=$(echo $miner_stat | jq ".gpus[$i].gpu_id")
		local hashrate=$(echo $miner_stat | jq ".gpus[$i].hashrate")
		hs[$gpu_id]=$((hashrate/1000))
	done
#	for (( i=0; i < ${GPU_COUNT_NVIDIA}; i++ )); do
#		hs[$i]=0
#	done
}

get_nvidia_cards_temp(){
	echo $(jq -c "[.gpus[].temperature]" <<< $miner_stat)
}

get_nvidia_cards_fan(){
	echo $(jq -c "[.gpus[].fan_speed]" <<< $miner_stat)
}

get_miner_uptime(){
	local uptime=$(echo $miner_stat | jq ".uptime")
	[[ $uptime == "null" ]] && uptime=0
	echo $uptime
}

get_miner_algo(){
#	local algo="x16r"
#	
#	for i in "${algo_avail[@]}"
#	do
#		if [[ ! -z $(echo $CUSTOM_USER_CONFIG | grep $i) ]]; then
#			algo=$i
#			break
#		fi
#	done
#	echo $algo
	echo $(jq -r -c '.algorithm' <<< "$miner_stat")
}

get_miner_shares_ac(){
	local acc=$(echo $miner_stat | jq ".accepted_count")
	[[ $acc == "null" ]] && acc=0
	echo $acc
}

get_miner_shares_rj(){
	local rej=$(echo $miner_stat | jq ".rejected_count")
	[[ $rej == "null" ]] && rej=0
	echo $rej
}

get_total_hashes(){
	local total=$(echo $miner_stat | jq ".hashrate")
	[[ $total == "null" ]] && total=0
	echo $((total/1000))
}

#######################
# MAIN script body
#######################


miner_stat=`echo 'summary' | nc -w $API_TIMEOUT localhost $API_PORT`

#echo $miner_stat

if [[ $? -ne 0 ]]; then
	echo -e "${YELLOW}Failed to read miner stats from localhost:${API_PORT}${NOCOLOR}"
	stats=""
	khs=0
	return 1
fi

#miner_stat=`cat stat.json`

[[ -z $GPU_COUNT_NVIDIA ]] &&
	GPU_COUNT_NVIDIA=`gpu-detect NVIDIA`

	get_cards_hashes					# hashes array
	hs_units='khs'						# hashes utits
	local temp=$(get_nvidia_cards_temp)		# cards temp
	local fan=$(get_nvidia_cards_fan)			# cards fan
	uptime=$(get_miner_uptime)			# miner uptime
	algo=$(get_miner_algo)				# algo
	# A/R shares by pool
	ac=$(get_miner_shares_ac)
	rj=$(get_miner_shares_rj)
	

#	# make JSON
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

# debug output
#echo temp:   $temp
#echo fan:    $fan
#echo stats:  $stats
#echo khs:    $khs
#echo uptime: $uptime

##echo hs:       ${hs[@]}
##echo hs_units: $hs_units
##echo temp:     $temp
##echo fan:      $fan
##echo uptime    $uptime
##echo "ac/rj":  $ac $rj
##echo algo:     $algo
