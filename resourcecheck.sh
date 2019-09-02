#!/usr/bin/env bash
# Author : chrotek
# TODO   : fix the sar logs variables that i accidentaly hardcoded
#          fix parsing broken because lvm
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

# Check disk usage
check_disk_usage() {
  diskmounts=$(lsblk -nl | awk {'print $7'} | grep -vE 'SWAP|/boot/'| awk NF | sort -n)
  longestName=0

  # Work out the longest disk name, and buffer the output columns accordingly
  for disk in $diskmounts;do
      nameCharCount=${#disk}
      if [ ${#disk} -gt $longestName ]
      then
          longestName=${#disk}
      fi
  done
  bufferCharCount=$((longestName+1))

  # Output the disk info
  printf "%s Disks (%% Full) %s\n" "---" "---"
  for disk in $diskmounts;do
      percentfull=$(df -h $disk | grep -v "Filesystem"| awk {'print $5'} | tr -d "%")
      printf "%*s| %s%% \n" -$bufferCharCount "$disk" "$(color_percent $percentfull)"
  done
}

# Functions to parse sar logs
getSarCPULogs () {

  if [ $startDateNum -gt $todayDateNum ]
  then
      for i in $(eval echo "{$startDateNum..31} {1..$todayDateNum}");do
              printf "$(sar -q -f $sar_log_path/sa$i 2>/dev/null | head -n1 | awk {'print $4'})" > /tmp/date
              sar -q -f $sar_log_path/sa$i 2>/dev/null | while read line ; do
                  printf "%s-$line \n" "$(cat /tmp/date)"
              done;
      done
  else [ $startDateNum -lt $todayDateNum ]
      for i in $(eval echo "{$startDateNum..$todayDateNum}");do
              printf "$(sar -q -f $sar_log_path/sa$i 2>/dev/null | head -n1 | awk {'print $4'})" > /tmp/date
              sar -q -f $sar_log_path/sa$i 2>/dev/null | while read line ; do
                  printf "%s-$line \n" "$(cat /tmp/date)"
              done;
      done
  fi
}

calculateAverageCPULoad() {
  getSarCPULogs | grep Average | awk '{ total += $4; count++ } END { print total/count }'
}

calculateHighestCPULoadAndBreaches() {

  touch /tmp/highestLoad /tmp/loadBreachCount
  highestLoad=0
  loadBreachCount=0
  getSarCPULogs | while read line ; do
    read -ra lineArray <<< "$line"

    lineCPULoad=${lineArray[3]}
    lineDateTime=${lineArray[0]}
    # Check if highest
    numx='^[0-9]+\.[0-9]+$'
    if [[ ! -z "$lineCPULoad" ]] && [[ "$lineCPULoad" =~ $numx ]] && [[ $(awk "BEGIN{print($lineCPULoad<$highestLoad);exit}") -eq "0" ]]
    then
        highestLoad=$lineCPULoad
	echo $lineDateTime > /tmp/highestLoadDateTime
        echo $highestLoad > /tmp/highestLoad
    fi
    # Check if higher than cpuCoreCount , Increment the loadBreachCount if so
    if [[ ! -z "$lineCPULoad" ]] && [[ "$lineCPULoad" =~ $numx ]] && [[ $(awk "BEGIN{print($lineCPULoad<$cpuCoreCount);exit}") -eq "0" ]]
    then
        ((loadBreachCount++))
        echo $loadBreachCount > /tmp/loadBreachCount
    fi
  done
  highestLoad=$(cat /tmp/highestLoad)
  highestLoadDateTime=$(cat /tmp/highestLoadDateTime | sed 's/-/ at /')
  loadBreachCount=$(cat /tmp/loadBreachCount)
  
  ## Load to percent
  # Do the math: count/total
  highestLoadPercent1=$(awk "BEGIN{printf ($highestLoad / $cpuCoreCount);exit}")
  # Convert to percent
  highestLoadPercent=$(awk "BEGIN{printf ($highestLoadPercent1*100);exit}")

}

# Info Dump
info_dump() {
    printf "%s Memory %s \n" "---" "---"
    printf "Total | %s Mb\n" "$(kb_mb_convert $totalMemory)"
    printf "Used  | %s Mb\n" "$(kb_mb_convert $usedMemory)"
    printf "Used %%: %s%% \n" "$(color_percent $usedMemoryPercent)"
    printf "%s CPU %s\n" "---" "---"
    printf "Cores | %s\n" "$cpuCoreCount"
    printf "Load  | %s\n" "$cpuLoad"
    printf "Load%% | %s%%\n" "$(color_percent $cpuLoadPercent)"
}

# Common Variables
totalMemory=$(grep "MemTotal" /proc/meminfo | awk {'print $2'})
cpuCoreCount=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')

# Check some args were supplied, if not, re-run with -n for live resources
if [ $# -eq 0 ]
then
    $0 -n
fi

# Check resources
while getopts 'nth' OPTION; do
  case "$OPTION" in
    n)
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
      # Easy Switch between 1,5,15 mins loadavg (ONLY FOR -n SWITCH)
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
                        "

      for dir in $sar_log_locations; do
          if [ -d $dir ]; then
	      sar_log_path=$dir
          fi
      done

      while getopts 'd w m l:' TIMESPAN; do
        case "$TIMESPAN" in
          d)
	    dayCount=1
            ;;
      
          w)
            dayCount=7
            ;;
      
          m)
            dayCount=28
            ;;
	  l)
	    dayCount=$OPTARG
	    ;;
          ?)
            giveUsageThenQuit
            ;;
        esac

	# Confirm we actually have logs for the amount of days given
        dayLogCount=$(ls $sar_log_path/sa* -l | egrep 'sa[0-9][0-9]' | wc -l)
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
                      sar -r -f $sar_log_path/sa$i 2>/dev/null | grep Average
              done
          
          else [ $startDateNum -lt $todayDateNum ]
              for i in $(eval echo "{$startDateNum..$todayDateNum}");do
                      sar -r -f $sar_log_path/sa$i 2>/dev/null | grep Average
              done
          fi | awk '{sum = $2+$5+$6} ; { total += sum; count++ } END { print total/count }'
	}
        usedMemory=$(calculateAverageUsedMemory)
	usedMemoryPercent=$(awk "BEGIN{printf ($usedMemory / $totalMemory)*100 ;exit}"| awk '{printf "%.2f\n", $1}')
	
	# Calculate highest CPU Load and How many times the system was overloaded
	calculateHighestCPULoadAndBreaches

	# Dump the info
	info_dump
        printf "Highest load observed    | %s on %s \n" "$highestLoad" "$highestLoadDateTime"
        printf "Highest load %% observed  | %s%% on %s \n" "$(color_percent $highestLoadPercent)" "$highestLoadDateTime"
        printf "Times CPU was overloaded | %s \n" "$loadBreachCount"

	# DISK Space
        check_disk_usage
      done;;     

    h)
      giveUsageThenQuit
      ;;
    ?)
      giveUsageThenQuit
      ;;
  esac
done
shift "$(($OPTIND -1))"
extraArgs=$*

# Cleanup
rm -f /tmp/highestLoad /tmp/date /tmp/loadBreachCount /tmp/highestLoadDateTime
