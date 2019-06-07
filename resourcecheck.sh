#!/usr/bin/env bash

# TODO LIST
### Make output Prettier
# Colors
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
SET='\033[0m'
COLOR=$SET

giveUsageThenQuit() {
  printf "USAGE: %s <options>
  Possible Options :
  -n now - print current resources
  " "$0"
  exit 1
}

color_percent() {

  inputnumber=$1
  # Color the input number green if less than 50
  if [ $(awk "BEGIN{print($inputnumber>50);exit}") -eq 0 ]
  then
      COLOR=$GREEN
  # Color the input number yellow if more than 50 but less than 90

  elif [ $(awk "BEGIN{print($inputnumber<50);exit}") -eq 0 ] && [ $(awk "BEGIN{print($inputnumber>90);exit}") -eq 0 ]
  then
      COLOR=$YELLOW
  # Color the input number green if more than 90
  elif [ $(awk "BEGIN{print($inputnumber<89);exit}") -eq 0 ]
  then
      COLOR=$LIGHTRED
  fi
  # Print the colored number, and set color back to normal
  printf "${COLOR}%s${SET}\n" "$inputnumber" 
}
# Convert Kb to Mb
kb_mb_convert() {
  output=$(($1/1024))
  printf $output
}

#Check packages installed
## sar

# Find sar logs
## Possible locations:
### /var/log/sysstat
##v# /var/log/sa

# Check resources


while getopts 'ntd:' OPTION; do
  case "$OPTION" in
    n)
      printf "N option , ARG: %s" "$OPTARG"

      ## Live
      ### Memory
      
      # Memory stats in kB
      totalMemory=$(grep "MemTotal" /proc/meminfo | awk {'print $2'})
      freeMemory=$(grep "MemFree" /proc/meminfo | awk {'print $2'})
      availableMemory=$(grep "MemAvailable" /proc/meminfo | awk {'print $2'})
      usedMemory=$(awk "BEGIN{printf ($totalMemory - $availableMemory);exit}")
      usedMemoryPercent=$(awk "BEGIN{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')
      freeMemoryPercent=$(awk "BEGIN{printf ($usedMemoryPercent - $totalMemory);exit}")
      
      ### CPU
      cpuCoreCount=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
      loadOne=$(cat /proc/loadavg | awk {'print $1'})
      loadFive=$(cat /proc/loadavg | awk {'print $2'})
      loadFifteen=$(cat /proc/loadavg | awk {'print $3'})
      # Easy Switch between 1,5,15 mins loadavg
      cpuLoad=$loadFive
      ## Load to percent
      # Do the math: count/total
      cpuLoadPercent1=$(awk "BEGIN{printf ($loadOne / $cpuCoreCount);exit}")
      # Convert to decimal
      cpuLoadPercent=$(awk "BEGIN{printf ($cpuLoadPercent1*100);exit}")
      
      # Print Section
      
      printf "%s Memory %s \n" "---" "---"
      printf "Total : %s Mb\n" "$(kb_mb_convert $totalMemory)"
      printf "Used  : %s Mb\n" "$(kb_mb_convert $usedMemory)"
      printf "Used %%: %s%% \n" "$(color_percent $usedMemoryPercent)"
      
      printf "%s CPU %s\n" "---" "---"
      printf "Cores : %s\n" "$cpuCoreCount"
      printf "Load  : %s\n" "$cpuLoad"
      printf "Load%% : %s%%\n" "$(color_percent $cpuLoadPercent)"
      
      ### DISK Space
      diskmounts=$(lsblk -nl | awk {'print $7'} | grep -vE 'SWAP|/boot/'| awk NF | sort -n)
      
      printf "%s Disks %s\n" "---" "---"
      for disk in $diskmounts;do
          percentfull=$(df -h $disk | grep -v "Filesystem"| awk {'print $5'} | tr -d "%")
          # can we maybe work out the longest mount name and change the buffer accordingly?
          printf "%-20s| %-5s%% \n" "$disk" "$(color_percent $percentfull)"
      done

      ;;

    t)
      shift "$(($OPTIND -1))"
      TIMESPAN=$*
      printf "T option , ARG: %s, extras: $TIMESPAN \n" "$OPTARG"

      while getopts 'd w m' TIMESPAN; do
        case "$TIMESPAN" in
          d)
            printf "day\n"
            ;;
      
          w)
            printf "week\n"
      
            ;;
      
          m)
            printf "month\n"
      
            ;;
          ?)
            giveUsageThenQuit
            ;;
        esac
      done ;;
      
    d)
      printf "D option , ARG: %s" "$OPTARG"

      ;;
    ?)
      giveUsageThenQuit
      ;;
  esac
done
shift "$(($OPTIND -1))"
extraArgs=$*


# DEBUG
# echo "extras $extraArgs"
