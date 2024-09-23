#!/bin/bash

./benchmark-nodeos/monitor_script.sh &
MONITOR_PID=$$

nodeos --config /home/enf-user/config/heap-mode.ini \
--data-dir /data \
--genesis-json /home/enf-user/config/genesis.json \
--terminate-at-block 10000

sleep 10
kill $MONITOR_PID
