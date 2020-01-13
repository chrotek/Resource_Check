# resourcecheck.sh

Script to analyze resource consumption for a Linux device. 

#### Disclaimer
    
    This script is still a work in progress. There are still some bugs as the files it uses aren't always formatted exactly the same way.
    If you run this and get any errors, don't trust the information it's giving you.
    You can avoid errors by only requesting today's logs ( replace <options> with tl0 )

#### Usage:

    ./resourcecheck.sh <options>

Or if you don't need to download:

    curl -s https://raw.githubusercontent.com/chrotek/Resource_Check/master/resourcecheck.sh | bash -s -- -<options>


#### Possible Options :

    -n now - print current resources

    -t timespan - print average consumption for an amount of time

  Required options for timespan:
  
    -d - day
    
    -w - week
    
    -m - month
    
    -l x - last x days

  For Example:
  
        ./resourcecheck.sh -tw # Show averages over the past week
