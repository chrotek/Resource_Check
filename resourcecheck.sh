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

# Memory stats in kB
totalMemory=$(grep "MemTotal" /proc/meminfo | awk {'print $2'})
freeMemory=$(grep "MemFree" /proc/meminfo | awk {'print $2'})
availableMemory=$(grep "MemAvailable" /proc/meminfo | awk {'print $2'})
usedMemory=$((totalMemory - availableMemory))
# usedMemoryPercent=$(((usedMemory / totalMemory)*100))
usedMemoryPercent_bc=$(printf '%.3f\n' $(echo "$usedMemory / $totalMemory" | bc -l ))
usedMemoryPercent=$(printf "\n" |awk "{printf ($usedMemory / $totalMemory)*100 ;exit}")
### CPU

### DISK Space



# DEBUG Section
printf "Total Memory    : %s \n" "$totalMemory"
printf "Free Memory     : %s \n" "$freeMemory"
printf "Available Memory: %s \n" "$availableMemory"
printf "Used Memory     : %s \n" "$usedMemory"
printf "Used Memory %%   : %s \n" "$usedMemoryPercent"



#

printf "\n" |awk "{printf $usedMemory / $totalMemory ;exit}"
echo
printf "\n" |awk "{printf ($usedMemory / $totalMemory)*100 ;exit}"
echo






