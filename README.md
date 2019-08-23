# resourcecheck.sh

Script to analyze resource consumption for a Linux device. 

#### Usage:

./resourcecheck.sh \<options>

Or if you don't need to download:

    curl -s https://raw.githubusercontent.com/chrotek/Resource_Check/master/resourcecheck.sh | bash -s -- -\<options>


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
