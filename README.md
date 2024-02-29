# Simple-Command-Builder
## Its for easier command building like:
###### docker-compose run --rm freqtrade backtesting --config user_data/config-nfiv7.json --data-format-ohlcv feather --timerange 20240201-20240202 --export trades --cache none

#### For one-click backtest, hyperopt, download data, to speed up the process of skipping each time copping and pasting or editing the commands in to terminal, colorus for aesthetics :)
#### And even if you have a farm of bots you can automate uploading strategies with updated parameters to designated IP address using SSH with one click

## I made it for PowerShell and Linux, to use with docker run on windows and from environment in linux 
###### (but if you run docker just add docker-compose run --rm but idk why would you do that)


#### You can easily adjust command and default parameters to your needs but mine I found optimal for daily use on my 32 core on 128GB RAM
#### If you don't want it to crash start with two workers and then increase till crashes, each time you increase --timerange on Hypoeropt the worker's might crash so you have to lower (days) or decrease number of workers (its all about your ram)
##### Same with backtesting will cause memory bottleneck and crash if you don't have enough ram for --timerange specified

# !!! Before You start !!! You need to edit your location of files

## For Backtest and Hypeorpt
#### cd 'C:\Users\...\Freqtrade'
## Only Hypeorpt
#### $customLoss = Get-CustomHyperoptLoss "C:\Users\...\Freqtrade\user_data\hyperopts"

# And edit/add information for File distributer:
##### @{ "name" = "name"; "ip" = "       "; "username" = "          "; "destination_dir" = "/home/.../Servers/Freqtrade/user_data/strategies" },
##### $source_dir = "C:\Users\...\Freqtrade\user_data\strategies"
##### $strategy_distribution_file = "C:\Users\...\Freqtrade\user_data\strategy_distribution.json"
