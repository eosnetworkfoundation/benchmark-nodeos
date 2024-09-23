#!/bin/bash

./benchmark-nodeos/monitor_script.sh &
MONITOR_PID=$!

[ -f /data/nodeos.log ] && :> /data/nodeos.log
nodeos --config /home/enf-replay/config/heap-mode.ini \
--data-dir /data \
--genesis-json /home/enf-replay/config/genesis.json \
--terminate-at-block 10000 > /data/nodeos.log

set +x
kill $MONITOR_PID
set -x
