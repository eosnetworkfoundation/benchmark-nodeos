#!/bin/bash

########
# Runs an Nodeos syncing up to exSat Testnet
# Used to run benchmakring node and collecting stats
# Starts from Block Num 1033687 as fat blocks start around 1300000
#######

# optional title set in host file and stat file
TITLE=${1}
# The nodeos config we will use
CONFIG=${2:-/home/enf-replay/benchmark-nodeos/config/heap-mode.ini}
PEER=${3:-172.31.71.45:9876}
cd /home/enf-replay/benchmark-nodeos || exit
# get the commit hash if we want to see exact version later
COMMIT_HASH=$(git rev-parse HEAD)
cd /home/enf-replay || exit

# clean up first
[ -f /data/nodeos.log ] && :> /data/nodeos.log
# remove state files
for f in /data/state/chain_head.dat /data/state/shared_memory.bin /data/state/code_cache.bin \
 /data/state-history/chain_state_history.log /data/state-history/chain_state_history.index \
 /data/state-history/trace_history.log /data/state-history/trace_history.index \
 /data/blocks/reversible/fork_db.dat
do
  [ -f ${f} ] && rm ${f}
done

./benchmark-nodeos/monitor_script.sh $(basename $CONFIG)-${COMMIT_HASH} $TITLE &
MONITOR_PID=$!

# start at 1,033,687 end 1,000,000 blocks later
# no block log
nodeos --config $CONFIG --data-dir /data \
--genesis-json /home/enf-replay/benchmark-nodeos/config/genesis.json \
--p2p-peer-address ${PEER} \
--terminate-at-block 700000 > /data/nodeos.log 2>&1

kill $MONITOR_PID

[ -f /home/enf-replay/runs.tar ] && mv /home/enf-replay/runs.tar /home/enf-replay/prev-runs.tar
tar cf /home/enf-replay/runs.tar /tmp/runs/
if [ $? -eq 0 ]; then
  rm /home/enf-replay/prev-runs.tar
fi
