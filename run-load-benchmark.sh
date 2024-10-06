#!/bin/bash

# optional title set in host file and stat file
TITLE=${1}
# The nodeos config we will use
CONFIG=${2:-/home/enf-replay/benchmark-nodeos/config/heap-mode.ini}
cd /home/enf-replay/benchmark-nodeos || exit
# get the commit hash if we want to see exact version later
COMMIT_HASH=$(git rev-parse HEAD)
cd /home/enf-replay || exit
./benchmark-nodeos/monitor_script.sh $(basename $CONFIG)-${COMMIT_HASH} $TITLE &
MONITOR_PID=$!

[ -f /data/nodeos.log ] && :> /data/nodeos.log
# remove state files
for f in /data/state/chain_head.dat /data/state/shared_memory.bin /data/state/code_cache.bin \
 /data/state-history/chain_state_history.log /data/state-history/chain_state_history.index \
 /data/state-history/trace_history.log /data/state-history/trace_history.index
do
  [ -f ${f} ] && rm ${f}
done
nodeos --config $CONFIG --data-dir /data \
--genesis-json /home/enf-replay/benchmark-nodeos/config/genesis.json \
--terminate-at-block 100000 > /data/nodeos.log 2>&1

kill $MONITOR_PID

[ -f /home/enf-replay/runs.tar ] && mv /home/enf-replay/runs.tar /home/enf-replay/prev-runs.tar
tar cf /home/enf-replay/runs.tar /tmp/runs/
if [ $? -eq 0 ]; then 
  rm /home/enf-replay/prev-runs.tar
fi
