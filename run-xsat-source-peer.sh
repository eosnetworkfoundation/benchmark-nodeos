#!/bin/bash

# The nodeos config we will use
CONFIG=${1:-/home/enf-replay/benchmark-nodeos/config/xsat-sync.ini}
FROM_SNAP=${2:-YES}
cd /home/enf-replay/benchmark-nodeos || exit
# get the commit hash if we want to see exact version later
COMMIT_HASH=$(git rev-parse HEAD)
cd /home/enf-replay || exit
./benchmark-nodeos/monitor_script.sh $(basename $CONFIG)-${COMMIT_HASH} &
MONITOR_PID=$!

SNAP=$(find /data/snapshots/ -name "*.bin*" | head -1)
SNAP_EXTENSION=${SNAP##*.}
# decompress if needed
if [ $SNAP_EXTENSION == "zst" ]; then
  # decompress if needed
  if [ ! -s ${SNAP%.*} ]; then
    echo "Decompressing snapshot"
    zstd -d $SNAP
  fi
  SNAP=${SNAP%.*}
fi
[ -f /data/nodeos.log ] && :> /data/nodeos.log
# remove state files
for f in /data/state/chain_head.dat /data/state/shared_memory.bin /data/state/code_cache.bin \
 /data/state-history/chain_state_history.log /data/state-history/chain_state_history.index \
 /data/state-history/trace_history.log /data/state-history/trace_history.index
do
  [ -f ${f} ] && rm ${f}
done

# gather host data complete , shutdown
kill $MONITOR_PID

if [ $FROM_SNAP == "YES" ]; then
  echo "Starting from snapshot"
  nohup nodeos --config $CONFIG --data-dir /data \
    --config $CONFIG \
    --snapshot $SNAP > /data/nodeos.log 2>&1 &
else
  echo "Starting from existing state"
  nohup nodeos --config $CONFIG --data-dir /data \
    --config $CONFIG > /data/nodeos.log 2>&1 &
fi
