#!/bin/bash

GIT_CONFIG=${1:-NA}
TITLE=${2:-$$ New Monitor}

RUNID=$(date -u +%j)$$
DIR="/tmp/runs"
STAT_FILE=${DIR}/stats-${RUNID}.txt
HOST_INFO=${DIR}/host-${RUNID}.txt

mkdir -p $DIR

echo ">> ${TITLE}" > $HOST_INFO
echo "MISC:" >> $HOST_INFO
[ -f /var/local/hwinfo.txt ] && cat /var/local/hwinfo.txt >> $HOST_INFO
echo "MISC:"  >> $HOST_INFO
echo -n "Date: ">> $HOST_INFO; date -u +"%Y-%m-%dT%H:%M:%SZ" >> $HOST_INFO
echo -n "Total Ram: ">> $HOST_INFO; free -g | grep Mem: | xargs | cut -d" " -f2 >> $HOST_INFO
echo -n "Total Swap: ">> $HOST_INFO; swapon --show=Size --noheadings >> $HOST_INFO
ALLOC_HUGE_PAGE=$(grep Hugetlb /proc/meminfo  | sed -e 's/Hugetlb:\s*\([0-9]*\)\s*kB/\1/')
let ALLOC_HUGE_PAGE=ALLOC_HUGE_PAGE/1024/1024
echo -n "Number of 1Gb Pages: ${ALLOC_HUGE_PAGE}">> $HOST_INFO;
echo -n "OS Info: ">> $HOST_INFO; uname -a  >> $HOST_INFO
echo -n "Processor Model: ">> $HOST_INFO; cat /proc/cpuinfo  | grep 'name'| uniq >> $HOST_INFO
echo -n "Num Processor: ">> $HOST_INFO; cat /proc/cpuinfo  | grep process| wc -l >> $HOST_INFO
echo -n "Nodeos Version: ">> $HOST_INFO; nodeos --full-version  >> $HOST_INFO
echo "Config File: ${GIT_CONFIG}">> $HOST_INFO

# accumulate statistics
# nodoes endpoint not avalible when loading/writing state
echo ">> ${TITLE}" > $STAT_FILE
stage="initialize"
nodeos_info="NA"
db_size_info="NA"
while true; do
  vm_stat=$(vmstat 1 1 | tail -1)
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') ${stage} ${vm_stat} ${nodeos_info} ${db_size_info}" | tee -a $STAT_FILE
  # reset
  nodeos_info="NA"
  db_size_info="NA"
  # snapshot
  IF_SNAP=$(tail -50 /data/nodeos.log | grep "Snapshot initialization" | wc -l)
  if [ "$IF_SNAP" -gt 0 ]; then
    stage="loading-snap"
  fi
  # chainbase read
  IF_CHAINBASE_LOAD=$(tail -50 /data/nodeos.log | grep 'CHAINBASE: Preloading "state" database' | wc -l)
  if [ "$IF_CHAINBASE_LOAD" -gt 0 ]; then
    stage="chainbase-load"
  fi
  # catch up via blocks log
  IF_REPLAY=$(tail -50 /data/nodeos.log | grep "replay_block_log" | wc -l)
  if [ "$IF_REPLAY" -gt 0 ]; then
    stage="replay"
  fi
  # catch up via peer sync
  IF_SYNC=$(tail -50 /data/nodeos.log | grep -E "Received block [0-9a-f]+" | wc -l)
  if [ "$IF_SYNC" -gt 0 ]; then
    stage="net-sync"
    nodeos_info=$(curl http://127.0.0.1:8888/v1/chain/get_info | jq -r .head_block_num) 2> /dev/null
    db_size_info=$(curl -X POST http://127.0.0.1:8888/v1/db_size/get | jq -r .used_bytes) 2> /dev/null
  fi
  # reach max block, don't need to include termination
  IF_END=$(tail -50 /data/nodeos.log | grep "reached configured maximum block" | wc -l)
  if [ "$IF_END" -gt 0 ]; then
    stage="terminating"
  fi
  # chainbase write
  IF_CHAINBASE_PERSIST=$(tail -50 /data/nodeos.log | grep 'CHAINBASE: Writing "state" database' | wc -l)
  if [ "$IF_CHAINBASE_PERSIST" -gt 0 ]; then
    stage="chainbase-persist"
  fi
  sleep 30
done
