#!/bin/bash

DIR="/tmpfsdata"

sudo mkdir -p $DIR
sudo mount -t tmpfs -o size=192G tmpfs $DIR
