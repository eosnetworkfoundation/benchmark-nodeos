#!/bin/bash

TITLE=${1:-$$ New Monitor}
GIT_CONFIG=${2:-NA}
RUNID=$(date -u +%j)$$
DIR="/tmp/runs"
STAT_FILE=${DIR}/stats-${RUNID}.txt
HOST_INFO=${DIR}/host-${RUNID}.txt

mkdir -p $DIR

echo ">> ${TITLE}" > $HOST_INFO
echo "MISC:" >> $HOST_INFO
[ -f /var/local/hwinfo.txt ] && cat /var/local/hwinfo.txt >> $HOST_INFO
echo "MISC:"  >> $HOST_INFO
{ echo -n "Date: "; date -u +"%Y-%m-%dT%H:%M:%SZ" } >> $HOST_INFO
{ echo -n "Total Ram: "; free -g | grep Mem: | xargs | cut -d" " -f2 } >> $HOST_INFO
{ echo -n "Total Swap: "; swapon --show=Size --noheadings } >> $HOST_INFO
{ echo -n "Number of 1Gb Pages: "; grep HugePages_1048576kB /proc/meminfo } >> $HOST_INFO
{ echo -n "OS Info: "; uname -a } >> $HOST_INFO
{ echo -n "Processor Model: "; cat /proc/cpuinfo  | grep 'name'| uniq } >> $HOST_INFO
{ echo -n "Num Processor: "; cat /proc/cpuinfo  | grep process| wc -l } >> $HOST_INFO
{ echo -n "Nodeos Version: "; nodeos --full-version } >> $HOST_INFO

# accumulate statistics
echo ">> ${TITLE}" > $STAT_FILE
while true; do
  nodeos_info=$(curl http://127.0.0.1:8888/v1/chain/get_info | cut -d',' -f3,4) 2> /dev/null
  db_size_info=$(curl http://127.0.0.1:8888/v1/db_size/get | xargs | cut -d',' -f1-4) 2> /dev/null
  { echo -n "$(date -u +"%Y-%m-%dT%H:%M:%SZ") ${nodeos_info} ${db_size_info}"; vmstat 1 1 | tail -1 } | tee -a $STAT_FILE;
  sleep 30;
done
