#!/bin/bash

DIR="/tmpfsdata"

sudo mkdir -p $DIR
sudo mount -t tmpfs -o size=128G tmpfs $DIR
