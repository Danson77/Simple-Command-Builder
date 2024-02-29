# Define default parameters
$defaultTimerange = "20231001-20240103"
$defaultSpaces = "sell"
$defaultEpochs = "10000"
$defaultHyperoptLoss = "ProfitSquareSortinoSpringEfficiencyHyperOptLoss"
$defaultWorkers = "8"

# Helper functions for colored messages
function Write-ErrorLine {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-InfoLine {
    param([string]$Message)
    Write-Host $Message -ForegroundColor White
}

function Write-WarningLine {
    param([string]$Message)
    Write-Host $Message -ForegroundColor DarkYellow
}

function Write-ActionLine {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Tell {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Blue
}

# ChooseParameterMode function
function ChooseParameterMode {
    do {
        Write-WarningLine "Do you want to use default parameters? (Yes/No/Custom):"
        $choice = Read-Host
        switch ($choice.ToLower().Trim()) {
            'yes' {
				Write-Tell "Default parameters selected."
                return $true
            }
            'no' {
                Write-Tell "Custom parameters selected."
                return $false
            }
            'custom' {
                $customLoss = Get-CustomHyperoptLoss "C:\Users\...\Freqtrade\user_data\hyperopts"
                if ($customLoss) {
                    Write-Tell "Custom hyperopt loss selected."
                    $global:defaultHyperoptLoss = $customLoss
                    return $true
                } else {
                    Write-ErrorLine "Using default hyperopt loss function."
                    return $true
                }
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes', 'No', or 'Custom'."
            }
        }
    } while ($true)
}
# Function to get timerange input from the user
function Get-Timerange {
    do {
        Write-ActionLine "Enter the timerange (format: YYYYMMDD-YYYYMMDD):"
        $timerange = Read-Host
        if ($timerange -match '^\d{8}-\d{8}$') {
            return $timerange
        } else {
            Write-ErrorLine "Invalid input. Please enter the timerange in the format YYYYMMDD-YYYYMMDD."
        }
    } while ($true)
}

# Function to get spaces input from the user
function Get-Spaces {
    $validSpaces = @("all", "buy", "sell", "roi", "stoploss", "trailing", "trades", "protection", "default")
    do {
        Write-ActionLine "Choose spaces (can choose multiple, separated by space):"
        Write-WarningLine "all, buy, sell, roi, stoploss, trailing, trades, protection, default"
        $spaces = (Read-Host "Enter your choice").ToLower()  # Convert input to lowercase
        $spaceList = $spaces -split ' '
        
        # Check if all provided spaces are valid
        $allValid = $spaceList | ForEach-Object { $validSpaces -contains $_ }
        
        if ($allValid -contains $false) {
            Write-ErrorLine "Invalid input. Please enter valid space options separated by space (all lowercase)."
        } else {
            return $spaces
        }
    } while ($true)
}

# Function to get the number of epochs from the user
function Get-Epochs {
    do {
        Write-ActionLine "Enter the number of epochs (-e):" # Inform the user what to input
        $epochs = Read-Host # Capture the user's input
        if ($epochs -match '^\d+$' -and [int]$epochs -gt 0) {
            return $epochs
        } else {
            Write-ErrorLine "Invalid input. Please enter a positive integer for epochs."
        }
    } while ($true)
}

# Function to get the number of workers from the user
function Get-Workers {
    do {
        Write-ActionLine "Enter the number of workers:"
        $workers = Read-Host
        if ($workers -match '^\d+$' -and [int]$workers -gt 0) {
            return $workers
        } else {
            Write-ErrorLine "Invalid input. Please enter a positive integer for workers."
        }
    } while ($true)
}

# Function to get the hyperopt-loss type from the user
function Get-HyperoptLoss {
    do {
        Write-ActionLine "Choose the hyperopt-loss type:"
        Write-WarningLine "1: ShortTradeDurHyperOptLoss 		- (default legacy Freqtrade hyperoptimization loss function) - Mostly for short trade duration and avoiding losses."
        Write-WarningLine "2: OnlyProfitHyperOptLoss        	- takes only amount of profit into consideration."
        Write-WarningLine "3: SharpeHyperOptLoss            	- optimizes Sharpe Ratio calculated on trade returns relative to standard deviation."
        Write-WarningLine "4: SharpeHyperOptLossDaily   		- optimizes Sharpe Ratio calculated on daily trade returns relative to standard deviation."
        Write-WarningLine "5: SortinoHyperOptLoss       		- optimizes Sortino Ratio calculated on trade returns relative to downside standard deviation."
        Write-WarningLine "6: SortinoHyperOptLossDaily  		- optimizes Sortino Ratio calculated on daily trade returns relative to downside standard deviation."
        Write-WarningLine "7: MaxDrawDownHyperOptLoss   		- Optimizes Maximum absolute drawdown."
        Write-WarningLine "8: MaxDrawDownRelativeHyperOptLoss	- Optimizes both maximum absolute drawdown while also adjusting for maximum relative drawdown."
        Write-WarningLine "9: CalmarHyperOptLoss            	- Optimizes Calmar Ratio calculated on trade returns relative to max drawdown."
        Write-WarningLine "10: ProfitDrawDownHyperOptLoss   	- Optimizes by max Profit & min Drawdown objective. DRAWDOWN_MULT variable within the hyperoptloss file can be adjusted to be stricter or more flexible on drawdown purposes."
        Write-WarningLine "11: *Custom*                     	- Choose custom hyperopt loss function"
        $choice = Read-Host "Enter your choice"

        switch ($choice) {
            '1' { return "ShortTradeDurHyperOptLoss" }
            '2' { return "OnlyProfitHyperOptLoss" }
            '3' { return "SharpeHyperOptLoss" }
            '4' { return "SharpeHyperOptLossDaily" }
            '5' { return "SortinoHyperOptLoss" }
            '6' { return "SortinoHyperOptLossDaily" }
            '7' { return "MaxDrawDownHyperOptLoss" }
            '8' { return "MaxDrawDownRelativeHyperOptLoss" }
            '9' { return "CalmarHyperOptLoss" }
            '10' { return "ProfitDrawDownHyperOptLoss" }
            '11' {
                Write-Tell "Custom hyperopt loss selected."
                return "Custom"
            }
            default {
                Write-ErrorLine "Invalid choice. Please enter a number between 1 and 11."
            }
        }
    } while ($true)
}

# Function to get the custom hyperopt loss file from the user
function Get-CustomHyperoptLoss {
    param($folderPath)

    Write-ActionLine "Available custom hyperopt loss files:"
    $lossFiles = Get-ChildItem -Path $folderPath -Filter *.py
    if ($lossFiles.Count -gt 0) {
        for ($i = 0; $i -lt $lossFiles.Count; $i++) {
            Write-WarningLine "$($i + 1): $($lossFiles[$i].Name)"
        }
        
        $choiceIndex = Read-Host "Enter the number corresponding to custom hyperopt loss file"
        if ($choiceIndex -ge 1 -and $choiceIndex -le $lossFiles.Count) {
            $choiceFileName = $lossFiles[$choiceIndex - 1].FullName
            $choiceContent = Get-Content $choiceFileName
            $className = ($choiceContent | Select-String -Pattern "class (.+)\(IHyperOptLoss\):").Matches.Groups[1].Value
            return $className
        } else {
            Write-ErrorLine "Invalid choice. Please enter a number between 1 and $($lossFiles.Count)."
            return $null
        }
    } else {
        Write-ErrorLine "No custom hyperopt loss files found in the specified folder."
        return $null
    }
}

# Function to get the number of workers from the user with default value
function Get-WorkersOrDefault {
    $workers = Get-Workers
    if (-not $workers) {
        Write-Tell "Using default number of workers: $defaultWorkers"
        return $defaultWorkers
    } else {
        return $workers
    }
}

# Implementation of default parameters choice with dynamic color output based on choice
$useDefaultParameters = ChooseParameterMode
if ($useDefaultParameters) {
    $timerange = $defaultTimerange
    $spaces = $defaultSpaces
    $epochs = $defaultEpochs
    $hyperoptLoss = $defaultHyperoptLoss
    $workers = $defaultWorkers
} else {
    # Get parameters from the user
    $timerange = Get-Timerange
    $spaces = Get-Spaces
    $epochs = Get-Epochs
	
    # Choose hyperopt loss function
    $hyperoptLoss = Get-HyperoptLoss
    if ($hyperoptLoss -eq "Custom") {
        $customLoss = Get-CustomHyperoptLoss "C:\Users\...\Freqtrade\user_data\hyperopts"
        if ($customLoss) {
            $hyperoptLoss = $customLoss
        } else {
            Write-ErrorLine "Using default hyperopt loss function."
            $hyperoptLoss = $defaultHyperoptLoss
        }
    }
    
    # Get the number of workers
    $workers = Get-WorkersOrDefault
}

# Define the Docker command as a script block for easier reuse
$dockerCommand = {
    param($timerange, $spaces, $epochs, $hyperoptLoss, $workers)
    
    cd 'C:\Users\...\Freqtrade'
    $cmd = "docker-compose run --rm freqtrade hyperopt --config user_data/config.json --timeframe 5m --data-format-ohlcv feather -j $workers --hyperopt-loss $hyperoptLoss --spaces $spaces --timerange $timerange -e $epochs"
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}

# Initially run the Docker command
& $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -hyperoptLoss $hyperoptLoss -workers $workers

# Loop for user input
$exitLoop = $false
do {
    Write-ActionLine "Type 'retry' to use same parameters, 'new' to enter new parameters, or 'exit' to close this window"
    $input = Read-Host # Capture user input after displaying the message
    switch ($input) {
        'retry' {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -hyperoptLoss $hyperoptLoss -workers $workers
        }
        'new' {
            $useDefaultParameters = ChooseParameterMode
            if ($useDefaultParameters) {
                $timerange = $defaultTimerange
                $spaces = $defaultSpaces
                $epochs = $defaultEpochs
                $hyperoptLoss = $defaultHyperoptLoss
                $workers = $defaultWorkers
            } else {
                $timerange = Get-Timerange
                $spaces = Get-Spaces
                $epochs = Get-Epochs
                $hyperoptLoss = Get-HyperoptLoss
                if ($hyperoptLoss -eq "Custom") {
                    $customLoss = Get-CustomHyperoptLoss "C:\Users\...\Freqtrade\user_data\hyperopts"
                    if ($customLoss) {
                        $hyperoptLoss = $customLoss
                    } else {
                        Write-ErrorLine "Using default hyperopt loss function."
                        $hyperoptLoss = $defaultHyperoptLoss
                    }
                }
                $workers = Get-WorkersOrDefault
            }
            Write-WarningLine "Running command with new parameters..."
            & $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -hyperoptLoss $hyperoptLoss -workers $workers
        }
        'exit' {
            Write-InfoLine "Exiting..."
            $exitLoop = $true # Set the flag to true to exit the loop
            break
        }
        default {
            Write-ErrorLine "Invalid input. Please type 'retry', 'new', or 'exit'."
        }
    }
} while (-not $exitLoop) # Loop until $exitLoop is true
