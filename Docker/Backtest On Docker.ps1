# Define default parameters
$defaultTimerange = "20240101-20250601"
$defaultUseCache = $false

# Helper functions for colored messages
function Write-ErrorLine { param([string]$Message); Write-Host $Message -ForegroundColor Red }
function Write-InfoLine { param([string]$Message); Write-Host $Message -ForegroundColor White }
function Write-WarningLine { param([string]$Message); Write-Host $Message -ForegroundColor DarkYellow }
function Write-ActionLine { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Tell { param([string]$Message); Write-Host $Message -ForegroundColor Blue }

# Function to choose a backtest config# Function to choose a backtest config
function Select-BacktestOrder {
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
            $configNumber = ([regex]::Match($config.Name, 'config-(\d+)\.json')).Groups[1].Value
            $containerName = "Backtest_$configNumber"            
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
        Write-ActionLine "Enter the timerange (format: YYYYMMDD-YYYYMMDD):"
        $timerange = Read-Host
        if ($timerange -match '^\d{8}-\d{8}$') {
            return $timerange
        } else {
            Write-ErrorLine "Invalid input. Please enter the timerange in the format YYYYMMDD-YYYYMMDD."
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
            'y' {
                Write-Host "Cache will be enabled."
                return $true
            }
            'no' {
                Write-Tell "Cache will be disabled."
                return $false
            }
            'n' {
                Write-Host "Cache will be disabled."
                return $false
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes'/'Y'or 'No'/'N'."
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
            'y' {
                Write-Host "Max open trades will be disabled."
                return $true
            }
            'no' {
                Write-WarningLine "Max open trades will remain enabled."
                return $false
            }
            'n' {
                Write-Host "Max open trades will remain enabled."
                return $false
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes'/'Y'or 'No'/'N'."
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
            'y' {
                Write-Host "Position stacking will be enabled."
                return $true
            }
            'no' {
                Write-WarningLine "Position stacking will remain disabled."
                return $false
            }
            'n' {
                Write-Host "Position stacking will remain disabled."
                return $false
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes'/'Y'or 'No'/'N'."
            }
        }
    } while ($true)
}

# MAIN SCRIPT START

# Force manual config selection — always ask user
$backtest = Select-BacktestOrder

if ($backtest) {
    # Extract config number from filename (e.g., config-3.json → 3)
    $configNumber = ([regex]::Match($backtest.ConfigFile, 'config-(\d+)\.json')).Groups[1].Value
    $containerName = "Backtest_$configNumber"
    $configFile = $backtest.ConfigFile
    $timerange = $defaultTimerange
    $useCache = $defaultUseCache
    # Optional toggles can be uncommented when needed
    #$disableMaxMarketPositions = Get-DisableMaxMarketPositionsOption
    #$enablePositionStacking = Get-EnablePositionStackingOption

    Write-InfoLine "Selected Container: $containerName"
    Write-InfoLine "Config File: $configFile"
} else {
    Write-ErrorLine "No backtest option selected. Exiting..."
    return
}

# Define the Docker command as a script block #$timeframe,
$dockerCommand = {
    param($containerName,$timerange, $useCache, $disableMaxMarketPositions, $enablePositionStacking, $configFile)
    cd 'K:\Freqtrade\'

    # Construct the Docker command with or without the cache option # --timeframe $timeframe
    $cacheOption = if ($useCache) { "" } else { "--cache none" }
    $maxMarketPositionsOption = if ($disableMaxMarketPositions) { "--disable-max-market-positions" } else { "" }
    $positionStackingOption = if ($enablePositionStacking) { "--enable-position-stacking" } else { "" }

    $cmd = "docker-compose run --name $containerName --rm freqtrade backtesting --config $configFile --data-format-ohlcv feather --export trades --timerange $timerange $cacheOption $maxMarketPositionsOption $positionStackingOption"
    
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}

# Initially run the Docker command #-timeframe $timeframe
& $dockerCommand -containerName $containerName -timerange $timerange -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking -configFile $configFile

# User input loop
$exitLoop = $false
do {
    Write-ActionLine "Select 'retry' (r), 'new' (n), 'exit' (e)"
    $input = (Read-Host).ToLower()

    switch ($input) {
        'retry' { }
        'r'     {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -containerName $containerName -timerange $timerange -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking -configFile $configFile
        }
        'new' { }
        'n' {
            # Manually select backtest config
            $backtest = Select-BacktestOrder
            if ($backtest) {
                # Extract config number from filename (e.g., config-3.json → 3)
                $configNumber = ([regex]::Match($backtest.ConfigFile, 'config-(\d+)\.json')).Groups[1].Value
                $containerName = "Backtest_$configNumber"
                $configFile = $backtest.ConfigFile
                $timerange = $defaultTimerange
                $useCache = $defaultUseCache

                # Optional: if you still want to allow manual input for these
                # $disableMaxMarketPositions = Get-DisableMaxMarketPositionsOption
                # $enablePositionStacking = Get-EnablePositionStackingOption

                Write-InfoLine "Selected Container: $containerName"
                Write-InfoLine "Config File: $configFile"
            } else {
                Write-ErrorLine "No backtest option selected. Exiting..."
                return
            }

            Write-WarningLine "Running command with selected parameters..."
            & $dockerCommand -containerName $containerName -timerange $timerange -useCache $useCache -disableMaxMarketPositions $disableMaxMarketPositions -enablePositionStacking $enablePositionStacking -configFile $configFile
        }
        'exit' { }
        'e'    {
            Write-InfoLine "Exiting..."
            $exitLoop = $true
        }
        default {
            Write-ErrorLine "Invalid input. Select 'retry' (r), 'new' (n), or 'exit' (e)."
        }
    }
} while (-not $exitLoop)
