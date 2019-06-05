#!/usr/bin/env bash

# Colors
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
SET='\033[0m'
COLOR=$SET

color_percent() {

  inputnumber=$1
  if [ $(awk "BEGIN{print($inputnumber>50);exit}") -eq 0 ]
  then
      COLOR=$GREEN
  elif [ $(awk "BEGIN{print($inputnumber<50);exit}") -eq 0 ] && [ $(awk "BEGIN{print($inputnumber>90);exit}") -eq 0 ]
  then
      COLOR=$YELLOW
  elif [ $(awk "BEGIN{print($inputnumber<89);exit}") -eq 0 ]
  then
      COLOR=$LIGHTRED
  fi
  printf "${COLOR}%s${SET}\n" "$inputnumber" 
}


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
usedMemoryPercent=$(printf "\n" |awk "{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')
freeMemoryPercent=$('100' - $usedMemoryPercent)

### CPU

### DISK Space
diskmounts=$(lsblk -nl | awk {'print $7'} | grep -vE 'SWAP|/boot/'| awk NF | sort -n)

for disk in $diskmounts;do
    percentfull=$(df -h $disk | grep -v "Filesystem"| awk {'print $5'} | tr -d "%")
    printf "%-20s| %-5s%% \n" "$disk" "$(color_percent $percentfull)"
done



# DEBUG Section

printf "%s Memory %s \n" "-----" "-----"
printf "Total     : %s \n" "$totalMemory"
printf "Free      : %s \n" "$freeMemory"
printf "Available : %s \n" "$availableMemory"
printf "Used      : %s \n" "$usedMemory"
printf "Used %%    : %s%% \n" "$(color_percent $usedMemoryPercent)"
