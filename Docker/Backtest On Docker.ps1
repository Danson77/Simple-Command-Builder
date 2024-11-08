# Define default parameters
$defaultTimerange = "20240101-20241001"
$defaultTimeframe = "5m"
$defaultUseCache = $false
$defaultDisableMaxMarketPositions = $false
$defaultEnablePositionStacking = $false

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
        Write-WarningLine "Do you want to use default parameters? (Yes/No): 20240101-20241001, 5m, No-Cache"
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
    $allowedTimeframes = @('1m', '5m', '15m', '1h', '4h', '1d')
    do {
        Write-ActionLine "Enter one of the Timeframe (e.g. $($allowedTimeframes -join ', '))"
        $input = Read-Host
        $timeframe = $input.ToLower()
        if ($allowedTimeframes -contains $timeframe) {
            Write-WarningLine "You've selected the timeframe: $timeframe"
            return $timeframe
        } else {
            Write-ErrorLine "Invalid input. The timeframe must be one of the following: $($allowedTimeframes -join ', '). Ensure to use lowercase letters."
        }
    } while ($true)
}

# Get-CacheOption function
function Get-CacheOption {
    do {
        Write-ActionLine "Do you want to enabled cache? (Yes/No)"
        $choice = Read-Host "Choice"
        switch ($choice.ToLower().Trim()) {
            'yes' {
                Write-WarningLine "Cache will be enabled."
                return $true
            }
            'no' {
                Write-Tell "Cache will be disabled."
                return $false
            }

            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes' or 'No'."
            }
        }
    } while ($true)
}

# Function to get option for --disable-max-market-positions
function Get-DisableMaxMarketPositionsOption {
    do {
        Write-ActionLine "Do you want to disable max market positions? (Yes/No)"
        $choice = Read-Host
        switch ($choice.ToLower().Trim()) {
            'yes' {
                Write-Tell "Max open trades will be disabled."
                return $true
            }
            'no' {
                Write-WarningLine "Max open trades will remain enabled."
                return $false
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes' or 'No'."
            }
        }
    } while ($true)
}

# Function to get option for --enable-position-stacking
function Get-EnablePositionStackingOption {
    do {
        Write-ActionLine "Do you want to enable position stacking? (Yes/No)"
        $choice = Read-Host
        switch ($choice.ToLower().Trim()) {
            'yes' {
                Write-Tell "Position stacking will be enabled."
                return $true
            }
            'no' {
                Write-WarningLine "Position stacking will remain disabled."
                return $false
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
    $disableMaxMarketPositions = $defaultDisableMaxMarketPositions
    $enablePositionStacking = $defaultEnablePositionStacking
} else {
    $timerange = Get-Timerange
    $timeframe = Get-Timeframe
    $useCache = Get-CacheOption
    $disableMaxMarketPositions = Get-DisableMaxMarketPositionsOption
    $enablePositionStacking = Get-EnablePositionStackingOption
}

# Define the Docker command as a script block
$dockerCommand = {
    param($timerange, $timeframe, $useCache, $disableMaxMarketPositions, $enablePositionStacking)
    cd 'M:\Freqtrade\'

    # Construct the Docker command with or without the cache option
    $cacheOption = if ($useCache) { "" } else { "--cache none" }
    $maxMarketPositionsOption = if ($disableMaxMarketPositions) { "--disable-max-market-positions" } else { "" }
    $positionStackingOption = if ($enablePositionStacking) { "--enable-position-stacking" } else { "" }

    $cmd = "docker-compose run --name Backtest --rm freqtrade backtesting --config user_data/config.json --data-format-ohlcv feather --export trades --timerange $timerange --timeframe $timeframe $cacheOption $maxMarketPositionsOption $positionStackingOption"
    
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}

# Initially run the Docker command
& $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking

# User input loop
$exitLoop = $false
do {
    Write-ActionLine "Type 'retry' to use same parameters, 'new' to enter new parameters, or 'exit' to close this window"
    $input = Read-Host
    switch ($input) {
        'retry' {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking
        }
        'new' {
            $useDefaultParameters = ChooseParameterMode
            if ($useDefaultParameters) {
                $timerange = $defaultTimerange
                $timeframe = $defaultTimeframe
                $useCache = $defaultUseCache
                $disableMaxMarketPositions = $defaultDisableMaxMarketPositions
                $enablePositionStacking = $defaultEnablePositionStacking
            } else {
                $timerange = Get-Timerange
                $timeframe = Get-Timeframe
                $useCache = Get-CacheOption
                $disableMaxMarketPositions = Get-DisableMaxMarketPositionsOption
                $enablePositionStacking = Get-EnablePositionStackingOption
            }
            Write-WarningLine "Running command with new parameters..."
            & $dockerCommand -timerange $timerange -timeframe $timeframe -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking
        }
        'exit' {
            Write-InfoLine "Exiting..."
            $exitLoop = $true
        }
        default {
            Write-ErrorLine "Invalid input. Please type 'retry', 'new', or 'exit'."
        }
    }
} while (-not $exitLoop)
