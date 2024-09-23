#!/bin/bash

TITLE=${1}
# The nodeos config we will use
CONFIG=/home/enf-replay/benchmark-nodeos/config/heap-mode.ini
cd /home/enf-replay/benchmark-nodeos || exit
# get the commit hash if we want to see exact version later
COMMIT_HASH=$(git rev-parse HEAD)
cd /home/enf-replay || exit
./benchmark-nodeos/monitor_script.sh $TITLE $(basename $CONFIG)-${COMMIT_HASH} &
MONITOR_PID=$!

[ -f /data/nodeos.log ] && :> /data/nodeos.log
nodeos --config $CONFIG \
--data-dir /data \
--genesis-json /home/enf-replay/benchmark-nodeos/config/genesis.json \
--terminate-at-block 10000 > /data/nodeos.log

set +x
kill $MONITOR_PID
set -x
