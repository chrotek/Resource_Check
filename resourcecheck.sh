#!/usr/bin/env bash

# Check packages installed
## sar

# Find sar logs
## Possible locations:
### /var/log/sysstat
### /var/log/sa

# Check resources

## Live 
### Memory
# Total Memory in kB
totalMemory=$(grep "MemTotal" /proc/meminfo | awk {'print $2'})

### CPU

### DISK Space



# DEBUG Section
printf "Total Memory: %s \n" "$totalMemory"
