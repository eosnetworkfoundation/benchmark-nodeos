# benchmark-nodeos
Benchmark Runs of Nodeos under different configurations. Original purpose detail exSat Memory Requirements.

## Overview
This repo, contains a several named configurations that are used to configure the Operating System, and Nodeos. With the named configuration Nodeos is started from a snapshot or genesis and run to a specific block height from block logs. During this replay lots of metrics from both the OS and Nodeos are collected to a file. At the end of the run some summary statistics will be reported. In addition the metrics file will contain the git commit hash and name of the configuration files used.

## Initial  
### Host Hardware
It depends on provider. Needs to be provided in a file. `/var/local/hwinfo.txt`

### System Configuration
Will collect
- start time `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- total ram `free -g | grep Mem: | xargs | cut -d" " -f2`
- total swap `swapon --show=Size --noheadings`
- number of 1Gb pages `grep HugePages_1048576kB /proc/meminfo`
- OS Info `uname -a`
- Processor Model `cat /proc/cpuinfo  | grep 'name'| uniq`
- Num Processor `cat /proc/cpuinfo  | grep process| wc -l`

### Nodeos Version
- full version of nodeos

### Nodeos Config
- git URL to file and git commit tag

## Running Metrics
Collected Every 60 seconds
### System Metrics
- time stamp `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- vmstat
   - procs running
   - memory swap, free, buff, cache
   - swap in and swap out
   - IO blocks in and blocks out
   - CPU user, system, idle, waiting for IO, stolen from VM
### Nodeos Metrics
- head block
- LIB
### DB Size Metrics
- free_bytes
- used_bytes
- reclaimable_bytes
- size

## Parsing Output
