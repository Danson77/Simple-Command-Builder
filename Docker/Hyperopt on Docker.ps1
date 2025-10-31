# Define default parameters
$defaultWorkers = "15"

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

# Function to choose a backtest config# Function to choose a backtest config
function Get-ConfigFile {
    # Ensure script is running from the correct directory
    $expectedPath = "K:\Freqtrade"
    if ((Get-Location).Path -ne $expectedPath) {
        Write-WarningLine "Switching to expected working directory: $expectedPath"
        try {
            Set-Location -Path $expectedPath
        } catch {
            Write-ErrorLine "Failed to change directory to $expectedPath. $_"
            return $null
        }
    }

    $configFolder = "user_data"
    if (-not (Test-Path $configFolder)) {
        Write-ErrorLine "Directory '$configFolder' does not exist. Current path: $(Get-Location)"
        return $null
    }

    $configs = Get-ChildItem -Path $configFolder -Filter "config-*.json" | Sort-Object Name
    if ($configs.Count -eq 0) {
        Write-ErrorLine "No config-*.json files found in '$configFolder'."
        return $null
    }

    do {
        Write-ActionLine "Available Backtest Configs:"
        $menuMap = @{}
        $index = 1

        foreach ($config in $configs) {
            $configName = $config.Name
            $containerName = "Backtest_$index"
            Write-InfoLine "$index. $containerName with $configName"
            $menuMap["$index"] = @{
                ContainerName = $containerName
                ConfigFile    = "$configFolder/$configName"
            }
            $index++
        }

        $choice = Read-Host "Enter your choice (1-$($configs.Count))"
        if ($menuMap.ContainsKey($choice)) {
            return $menuMap[$choice]
        } else {
            Write-ErrorLine "Invalid input. Please enter a number between 1 and $($configs.Count)."
        }
    } while ($true)
}

# Function to get timerange input from the user
function Get-Timerange {
    do {
        Write-ActionLine "Enter the timerange (format: YYYYMMDD-YYYYMMDD for example: 20240101-20250601 ):"
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
        Write-WarningLine "buy, sell, stoploss, trailing, roi, trades, protection, all, default"
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
        Write-WarningLine "1:   Short Trade Duration      - Favors short trade times and avoiding losses."
        Write-WarningLine "2:   Only Profit               - Focuses only on total profit."
        Write-WarningLine "3:   Sharpe                    - Targets high Sharpe Ratio (return vs. volatility) on trade returns."
        Write-WarningLine "4:   Sharpe Daily              - Same as Sharpe, but calculated on daily returns."
        Write-WarningLine "5:   Sortino                   - Targets high Sortino Ratio (return vs. downside risk) on trade returns."
        Write-WarningLine "6:   Sortino Daily             - Same as Sortino, but calculated on daily returns."
        Write-WarningLine "7:   Max DrawDown              - Minimizes the largest account drop (max drawdown)."
        Write-WarningLine "8:   Max DrawDown Relative     - Minimizes both largest drop and relative drop size."
        Write-WarningLine "9:   Calmar                    - Targets high Calmar Ratio (return vs. max drawdown)."
        Write-WarningLine "10:  Profit DrawDown           - Balances high profit with low drawdown. Adjust DRAWDOWN_MULT in file to make it stricter or looser."
        Write-WarningLine "11: *List of Customs*          - Shows a custom hyperopt loss functions."
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

# Implementation of default parameters choice with dynamic color output based on choice
# Always prompt the user for all values
$timerange = Get-Timerange
$config = Get-ConfigFile
$spaces = Get-Spaces
$epochs = Get-Epochs
$workers = Get-Workers
$hyperoptLoss = Get-HyperoptLoss

if ($hyperoptLoss -eq "Custom") {
    $customLoss = Get-CustomHyperoptLoss "K:\Freqtrade\user_data\hyperopts"
    if ($customLoss) {
        $hyperoptLoss = $customLoss
    } else {
        Write-ErrorLine "No custom loss selected. Please run again and choose correctly."
        exit 1
    }
}


# Define the Docker command as a script block for easier reuse     --enable-position-stacking --disable-max-market-positions --random-state 48669 29440  6319 
$dockerCommand = {
    param($timerange, $spaces, $epochs, $hyperoptLoss, $workers, $configFile)
    
    cd 'K:\Freqtrade'
    $cmd = "docker-compose run --name Hyperopt --rm freqtrade hyperopt --config $configFile --data-format-ohlcv feather --timerange $timerange --spaces $spaces -e $epochs -j $workers --hyperopt-loss $hyperoptLoss"
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}

# Initially run the Docker command
& $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -workers $workers -hyperoptLoss $hyperoptLoss -configFile $config.ConfigFile

# Loop for user input
$exitLoop = $false
do {
    Write-ActionLine "Type 'retry' (or 'r') to use same parameters, 'new' (or 'n') to enter new parameters, or 'exit' (or 'e') to close this window"
    $input = (Read-Host).ToLower()  # Normalize input for case-insensitivity

    switch ($input) {
        'retry' { $input = 'r' }
        'new'   { $input = 'n' }
        'exit'  { $input = 'e' }
    }

    switch ($input) {
        'r' {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -workers $workers -hyperoptLoss $hyperoptLoss -configFile $config.ConfigFile
        }
        'n' {
            # Prompt user again for all values
            $timerange = Get-Timerange
            $config = Get-ConfigFile
            $spaces = Get-Spaces
            $epochs = Get-Epochs
            $workers = Get-Workers
            $hyperoptLoss = Get-HyperoptLoss
            
            if ($hyperoptLoss -eq "Custom") {
                $customLoss = Get-CustomHyperoptLoss "K:\Freqtrade\user_data\hyperopts"
                if ($customLoss) {
                    $hyperoptLoss = $customLoss
                } else {
                    Write-ErrorLine "No custom loss selected. Please run again and choose correctly."
                    exit 1
                }
            }
            Write-WarningLine "Running command with new parameters..."
            & $dockerCommand -timerange $timerange -spaces $spaces -epochs $epochs -workers $workers -hyperoptLoss $hyperoptLoss -configFile $config.ConfigFile
        }
        'e' {
            Write-InfoLine "Exiting..."
            $exitLoop = $true
        }
        default {
            Write-ErrorLine "Invalid input. Please type 'retry', 'new', or 'exit'."
        }
    }
} while (-not $exitLoop)

