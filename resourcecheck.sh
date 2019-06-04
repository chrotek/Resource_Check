#!/usr/bin/env bash

# Colors
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
SET='\033[0m'
COLOR=$SET

#echo "${COLOR}COLOR${SET}"

#Check packages installed
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
#usedMemoryPercent_bc=$(printf '%.3f\n' $(echo "$usedMemory / $totalMemory" | bc -l ))
#usedMemoryPercent=$(printf "\n" |awk "{printf ($usedMemory / $totalMemory)*100}")
usedMemoryPercent=$(printf "\n" |awk "{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')
freeMemoryPercent=$(100 - usedMemoryPercent)

### CPU

### DISK Space
disknames=$(lsblk -nl | awk {'print $7'} | grep -vE 'SWAP|/boot/'| awk NF | sort -n)


# echo $disknames

for disk in $disknames;do
    # echo "DISK"$disk
    percentfull=$(df -h $disk | grep -v "Filesystem"| awk {'print $5'})
    # if disk is LOW,MEDIUM,HIGH full, set COLOR to RED,YELLOW or GREEN
    printf "%s \t %s \n" "$disk" "$percentfull"
    # echo "FILL"$percentfull
done



# DEBUG Section

printf "%s Memory %s \n" "-----" "-----"
printf "Total     : %s \n" "$totalMemory"
printf "Free      : %s \n" "$freeMemory"
printf "Available : %s \n" "$availableMemory"
printf "Used      : %s \n" "$usedMemory"
printf "Used %%    : %s%% \n" "$usedMemoryPercent"


