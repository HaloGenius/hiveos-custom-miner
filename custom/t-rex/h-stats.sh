#!/usr/bin/env bash

cd `dirname $0`
#. h-manifest.conf
#. debug.conf
#. /hive-config/wallet.conf
. /hive/custom/$CUSTOM_MINER/h-manifest.conf

#algo_avail=("balloon" "bcd" "bitcore" "c11" "hmq1725" "hsr" "lyra2z" "phi" "polytimos" "renesis" "sha256t" "skunk" "sonoa" "timetravel" "tribus" "x16r" "x16s" "x17")

stat_raw=`echo 'summary' | nc -w $API_TIMEOUT localhost $API_PORT`
#echo $stat_raw
if [[ $? -ne 0 ]]; then
	echo -e "${YELLOW}Failed to read miner stats from localhost:${API_PORT}${NOCOLOR}"
	stats=""
	khs=0
else
	stats=$(jq '{hs: [.gpus[].hashrate], hs_units: "hs", temp: [.gpus[].temperature], fan: [.gpus[].fan_speed], uptime: .uptime, ar: [.accepted_count, .rejected_count], bus_numbers:[.gpus[].gpu_id], algo: .algorithm}' <<< $stat_raw)

	# total hashrate in khs
#	local total=$(echo $miner_stat | jq ".hashrate")
#	[[ $total == "null" ]] && total=0
#	khs=$((total/1000))
	khs=$(jq ".hashrate/1000" <<< $stat_raw)
fi
