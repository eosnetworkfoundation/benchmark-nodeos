#!/bin/bash

DIR="/tmpfsdata"

sudo mkdir -p $DIR
sudo mount -t tmpfs -o size=100G tmpfs $DIR
