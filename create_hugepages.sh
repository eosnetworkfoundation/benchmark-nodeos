#!/bin/bash

# Disable Transparent Huge Pages
echo never | tee /sys/kernel/mm/transparent_hugepage/enabled
# Allocate many 1Gb Huge Pages
echo 100 | tee /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
