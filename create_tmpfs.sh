#!/bin/bash

DIR="/tmpfsdata"

sudo mkdir -p $DIR
sudo mount -t tmpfs -o size=24G tmpfs $DIR
