# Define default parameters
$defaultTimerange = "20220601-20240203"
$defaultTimeframe = "5m"
$defaultUseCache = $true
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
        Write-WarningLine "Do you want to use default parameters? (Yes/No):"
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
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes' or 'No'."
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
# Improved Get-Timeframe function with nicer user interaction
function Get-Timeframe {
    # List of allowed timeframes for selection
    $allowedTimeframes = @('1m', '5m', '15m', '1h', '4h', '1d')
    
    # Loop until valid input is received
    do {
        # Displaying the prompt with available options
        Write-ActionLine "Enter one of the Timeframe (e.g. $($allowedTimeframes -join ', '))"
        $input = Read-Host
        
        # Convert user input to lowercase to ensure case-insensitive comparison
        $timeframe = $input.ToLower()
        
        # Check if the converted lowercase input is within the allowed timeframes
        if ($allowedTimeframes -contains $timeframe) {
            Write-WarningLine "You've selected the timeframe: $timeframe"
            return $timeframe
        } else {
            Write-ErrorLine "Invalid input. The timeframe must be one of the following: $($allowedTimeframes -join ', '). Ensure to use lowercase letters."
        }
    } while ($true)
}
# Improved Get-CacheOption function with enhanced user interaction
function Get-CacheOption {
    do {
        # Prompt the user with a clear question
        Write-ActionLine "Do you want to disable cache? (Yes/No)"
        $choice = Read-Host "Choice"

        # Process the user's choice
        switch ($choice.ToLower().Trim()) {
            'yes' {
                Write-Tell "Cache will be disabled."
                return $false
            }
            'no' {
                Write-WarningLine "Cache will be enabled."
                return $true
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes' or 'No'."
            }
        }
    } while ($true)
}
# Main script execution
$useDefaultParameters = ChooseParameterMode
if ($useDefaultParameters) {
    $timerange = $defaultTimerange
    $timeframe = $defaultTimeframe
    $useCache = $defaultUseCache
} else {
    $timerange = Get-Timerange
    $timeframe = Get-Timeframe
    $useCache = Get-CacheOption
}
# Define the Docker command as a script block for easier reuse
$dockerCommand = {
    param($timerange, $timeframe, $useCache)
    cd 'C:\Users\Broni\OneDrive\Servers\Freqtrade'
    # Construct the Docker command with or without the cache option
    $cacheOption = if ($useCache) { "" } else { "--cache none" }
    $cmd = "docker-compose run --rm freqtrade backtesting --config user_data/config.json --data-format-ohlcv feather --export trades --timerange $timerange --timeframe $timeframe $cacheOption"
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}
# Initially run the Docker command
& $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache
# User input loop
$exitLoop = $false
do {
    Write-ActionLine "Type 'retry' to use same parameters, 'new' to enter new parameters, or 'exit' to close this window"
    $input = Read-Host # Capture user input after displaying the message
    switch ($input) {
        'retry' {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache
        }
        'new' {
            $useDefaultParameters = ChooseParameterMode
            if ($useDefaultParameters) {
                $timerange = $defaultTimerange
                $timeframe = $defaultTimeframe
                $useCache = $defaultUseCache
            } else {
                $timerange = Get-Timerange
                $timeframe = Get-Timeframe
                $useCache = Get-CacheOption
            }
            Write-WarningLine "Running command with new parameters..."
            & $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache
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
