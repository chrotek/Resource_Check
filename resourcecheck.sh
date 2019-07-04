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
  printf "\nUSAGE: %s <options>
  Possible Options :
  -n now - print current resources
  -t timespan - print average consumption for an amount of time
    Required options for timespan:
    -d - day
    -w - week
    -m - month
    -l x - last x days
  \n" "$0"
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

# Check some args were supplied
if [ $# -eq 0 ]
then
    printf "No Argument given!\n"
    giveUsageThenQuit
fi

# Check disk usage

check_disk_usage() {
  diskmounts=$(lsblk -nl | awk {'print $7'} | grep -vE 'SWAP|/boot/'| awk NF | sort -n)
  printf "%s Disks (%% Full) %s\n" "---" "---"
  for disk in $diskmounts;do
      percentfull=$(df -h $disk | grep -v "Filesystem"| awk {'print $5'} | tr -d "%")
      # can we maybe work out the longest mount name and change the buffer accordingly? #################################################
      printf "%-20s| %-5s%% \n" "$disk" "$(color_percent $percentfull)"
  done
}

# Info Dump
info_dump() {
    printf "%s Memory %s \n" "---" "---"
    printf "Total : %s Mb\n" "$(kb_mb_convert $totalMemory)"
    printf "Used  : %s Mb\n" "$(kb_mb_convert $usedMemory)"
    printf "Used %%: %s%% \n" "$(color_percent $usedMemoryPercent)"
    printf "%s CPU %s\n" "---" "---"
    printf "Cores : %s\n" "$cpuCoreCount"
    printf "Load  : %s\n" "$cpuLoad"
    printf "Load%% : %s%%\n" "$(color_percent $cpuLoadPercent)"
}

# Common Variables
totalMemory=$(grep "MemTotal" /proc/meminfo | awk {'print $2'})
cpuCoreCount=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')

# Check resources
while getopts 'nt' OPTION; do
  case "$OPTION" in
    n)
#      printf "N option , ARG: %s \n" "$OPTARG" # DEBUG

      ## Live
      ### Memory
      
      # Memory stats in kB, using awk because bash doesn't have a tool for floating point calculations.
      freeMemory=$(grep "MemFree" /proc/meminfo | awk {'print $2'})
      availableMemory=$(grep "MemAvailable" /proc/meminfo | awk {'print $2'})
      usedMemory=$(awk "BEGIN{printf ($totalMemory - $availableMemory);exit}")
      usedMemoryPercent=$(awk "BEGIN{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')
      freeMemoryPercent=$(awk "BEGIN{printf ($usedMemoryPercent - $totalMemory);exit}")
      
      ### CPU
      loadOne=$(cat /proc/loadavg | awk {'print $1'})
      loadFive=$(cat /proc/loadavg | awk {'print $2'})
      loadFifteen=$(cat /proc/loadavg | awk {'print $3'})
      # Easy Switch between 1,5,15 mins loadavg
      cpuLoad=$loadOne
      ## Load to percent
      # Do the math: count/total
      cpuLoadPercent1=$(awk "BEGIN{printf ($cpuLoad / $cpuCoreCount);exit}")
      # Convert to decimal
      cpuLoadPercent=$(awk "BEGIN{printf ($cpuLoadPercent1*100);exit}")
      
      # Print Section
      info_dump
      
      ### DISK Space
      check_disk_usage
      ;;

    t)
      shift "$(($OPTIND -1))"
      TIMESPAN=$*
#      printf "T option , ARG: %s, extras: $TIMESPAN \n" "$OPTARG" # DEBUG

      if [ -z "$TIMESPAN" ]
      then
	printf "t option given, but no timespan specified\n"
        giveUsageThenQuit
	exit
      fi     

      # Check SAR installed   # DEBUG
      if ! [ -x "$(command -v sar)" ]; then
	printf "ERROR: sar is not installed.\n"
	giveUsageThenQuit
      fi
      # Find Sar Logs
      sar_log_locations="
                         /var/log/sysstat
                         /var/log/sa
                         /fake/path
                        "

      for dir in $sar_log_locations; do
          if [ -d $dir ]; then
#              echo "Dir $dir exists" # DEBUG
	      sar_log_path=$dir
          fi
      done
#      echo "sar logs in $sar_log_path" # DEBUG

      while getopts 'd w m l:' TIMESPAN; do
        case "$TIMESPAN" in
          d)
            printf "day\n"
	    dayCount=1
            ;;
      
          w)
            printf "week\n"
            dayCount=7
            ;;
      
          m)
            printf "month\n"
            dayCount=31
            ;;
	  l)
	    dayCount=$OPTARG
            printf "last x days %s\n" "$dayCount"
	    ;;
          ?)
            giveUsageThenQuit
            ;;
        esac

	# Confirm we actually have logs for the amount of days given
        dayLogCount=$(ls /var/log/sysstat/sa* -l | egrep 'sa[0-9][0-9]' | wc -l)
        if [ $dayLogCount -lt $dayCount ]
        then
            printf "You Requested %s days of logs, but the system only has %s days stored.\nExiting" "$dayCount" "$dayLogCount"
            exit 1
        fi

	# Work out the date range from daycount
	todayDate=$(date '+%d %B')
	todayDateNum=$(date '+%d')
	startDate=$(date --date="$dayCount days ago" '+%d %B')
	startDateNum=$(date --date="$dayCount days ago" '+%d')

	printf "Average Resource Consumption for Date Range: %s - %s \n" "$startDate" "$todayDate"

	# Calculate Average Resource consumption from specified timespan
	# CPU Load
	calculateAverageCPULoad() {
          if [ $startDateNum -gt $todayDateNum ]
          then
              for i in $(eval echo "{$startDateNum..31} {1..$todayDateNum}");do
                      sar -q -f /var/log/sysstat/sa$i 2>/dev/null | grep Average
              done
          
          else [ $startDateNum -lt $todayDateNum ]
              for i in $(eval echo "{$startDateNum..$todayDateNum}");do
                      sar -q -f /var/log/sysstat/sa$i 2>/dev/null | grep Average
              done
          fi | awk '{ total += $4; count++ } END { print total/count }'
	}
	cpuLoad=$(calculateAverageCPULoad)
        ## Load to percent
	# Do the math: count/total
	cpuLoadPercent1=$(awk "BEGIN{printf ($cpuLoad / $cpuCoreCount);exit}")
	# Convert to decimal
	cpuLoadPercent=$(awk "BEGIN{printf ($cpuLoadPercent1*100);exit}")

	# Memory
	calculateAverageUsedMemory() {
          if [ $startDateNum -gt $todayDateNum ]
          then
              for i in $(eval echo "{$startDateNum..31} {1..$todayDateNum}");do
                      sar -r -f /var/log/sysstat/sa$i 2>/dev/null | grep Average
              done
          
          else [ $startDateNum -lt $todayDateNum ]
              for i in $(eval echo "{$startDateNum..$todayDateNum}");do
                      sar -r -f /var/log/sysstat/sa$i 2>/dev/null | grep Average
              done
          fi | awk '{sum = $2+$5+$6} ; { total += sum; count++ } END { print total/count }'
	}
        usedMemory=$(calculateAverageUsedMemory)
	usedMemoryPercent=$(awk "BEGIN{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')

	# Dump the info
	info_dump

	# DISK Space
        check_disk_usage
      done;;     
    ?)
      giveUsageThenQuit
      ;;
  esac
done
shift "$(($OPTIND -1))"
extraArgs=$*


# DEBUG
# echo "extras $extraArgs"
