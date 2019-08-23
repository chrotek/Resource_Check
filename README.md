# resourcecheck.sh

Script to analyze resource consumption for a Linux device. 

Usage:
./resourcecheck.sh \<options>

Possible Options :
-n now - print current resources
-t timespan - print average consumption for an amount of time
  Required options for timespan:
  -d - day
  -w - week
  -m - month
  -l x - last x days
