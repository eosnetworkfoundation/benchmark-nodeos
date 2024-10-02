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
echo -n "Number of 1Gb Pages: ">> $HOST_INFO;
grep HugePages_1048576kB /proc/meminfo || echo "0" >> $HOST_INFO
echo -n "OS Info: ">> $HOST_INFO; uname -a  >> $HOST_INFO
echo -n "Processor Model: ">> $HOST_INFO; cat /proc/cpuinfo  | grep 'name'| uniq >> $HOST_INFO
echo -n "Num Processor: ">> $HOST_INFO; cat /proc/cpuinfo  | grep process| wc -l >> $HOST_INFO
echo -n "Nodeos Version: ">> $HOST_INFO; nodeos --full-version  >> $HOST_INFO
echo "Config File: ${GIT_CONFIG}">> $HOST_INFO

# accumulate statistics
# nodoes endpoint not avalible when loading/writing state
# nodeos_info=$(curl http://127.0.0.1:8888/v1/chain/get_info | cut -d',' -f3,4) 2> /dev/null
# db_size_info=$(curl http://127.0.0.1:8888/v1/db_size/get | xargs | cut -d',' -f1-4) 2> /dev/null
echo ">> ${TITLE}" > $STAT_FILE
stage="initialize"
while true; do
  vm_stat=$(vmstat 1 1 | tail -1)
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') ${stage} ${vm_stat}" | tee -a $STAT_FILE
  # reach max block, don't need to include termination
  IF_END=$(tail -500 /data/nodeos.log | grep "reached configured maximum block" | wc -l)
  if [ "$IF_END" -gt 0 ]; then
    stage="terminating"
  fi
  # snapshot
  IF_SNAP=$(tail -100 /data/nodeos.log | grep "Snapshot initialization" | wc -l)
  if [ "$IF_SNAP" -gt 0 ]; then
    stage="loading-snap"
  fi
  # catch up
  IF_CATCHUP=$(tail -100 /data/nodeos.log | grep -e "replay_block_log" -e "Sending handshake generation" | wc -l)
  if [ "$IF_CATCHUP" -gt 0 ]; then
    stage="catchup"
  fi
  # chainbase write
  IF_CHAINBASE_LOAD=$(tail -100 /data/nodeos.log | grep 'CHAINBASE: Writing "state" database' | wc -l)
  if [ "$IF_CATCHUP" -gt 0 ]; then
    stage="chainbase-load"
  fi
  IF_CHAINBASE_PERSIST=$(tail -100 /data/nodeos.log | grep 'CHAINBASE: Preloading "state" database' | wc -l)
  if [ "$IF_CATCHUP" -gt 0 ]; then
    stage="chainbase-persist"
  fi



  sleep 30
done
