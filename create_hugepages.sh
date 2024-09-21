#!/bin/bash

# Disable Transparent Huge Pages
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
# Allocate many 1Gb Huge Pages
echo 100 | sudo tee /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
