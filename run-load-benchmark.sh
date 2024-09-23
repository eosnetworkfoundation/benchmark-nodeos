#!/bin/bash

./benchmark-nodeos/monitor_script.sh &
MONITOR_PID=$$

nodeos --config /home/enf-replay/config/heap-mode.ini \
--data-dir /data \
--genesis-json /home/enf-replay/config/genesis.json \
--terminate-at-block 10000 2>&1 > /data/nodeos.log

set +x
sleep 10
kill $MONITOR_PID
set -x
