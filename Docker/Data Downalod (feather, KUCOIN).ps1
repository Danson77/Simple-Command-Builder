# Define default parameters
$defaultTimerange = "20240101-20241100"
$defaultTimeframes = "1m 5m 15m 1h"
$defaultIncludeInactivePairs = $false  # Set to $true to include inactive pairs, $false otherwise
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
# ChooseParameterMode function
function ChooseParameterMode {
    do {
        Write-WarningLine "Do you want to use default parameters? (Yes/No):"
        $choice = Read-Host
        switch ($choice.ToLower().Trim()) {
            'y' {
				Write-Tell "Default parameters selected."
                return $true
            }
            'yes' {
				Write-Tell "Default parameters selected."
                return $true
            }
            'n' {
                Write-Tell "Custom parameters selected."
                return $false
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
function Get-Timeframes {
    # List of allowed timeframes for selection
    $allowedTimeframes = @('1m', '5m', '15m','30m', '1h', '2h', '4h', '6h', '12h','1d')
    # Loop until valid input is received
    do {
        # Displaying the prompt with available options
        Write-ActionLine "Enter the Timeframes (separated by spaces, e.g., 1m 5m 15m 30m 1h 2h 4h 6h 12h 1d):"
        $input = Read-Host
        
        # Convert user input to lowercase and split by spaces to handle multiple timeframes
        $inputTimeframes = $input.ToLower() -split ' '

        # Validate each input timeframe against allowed timeframes
        $allValid = $inputTimeframes | ForEach-Object {
            $allowedTimeframes -contains $_
        } | ForEach-Object {
            if (-not $_) { $false; return }
            $true
        }

        if ($allValid -notcontains $false) {
            Write-Tell "You've selected the timeframes: $($inputTimeframes -join ', ')"
            return $inputTimeframes -join ' '
        } else {
            Write-ErrorLine "Invalid input. Please enter valid timeframes separated by spaces. Allowed: $($allowedTimeframes -join ', ')."
        }
    } while ($true)
}
function Get-IncludeInactivePairs {
    do {
        # Display the question with colored output
        Write-WarningLine "Do you want to include inactive pairs? (Yes/No)"
        $choice = Read-Host
        
        # Convert the choice to lowercase for consistent comparison
        $choice = $choice.ToLower().Trim()
        
        switch ($choice) {
            'y' {
                Write-Tell "Including inactive pairs."
                return $true
            }
            'yes' {
                Write-Tell "Including inactive pairs."
                return $true
            }
            'n' {
                Write-Tell "Excluding inactive pairs."
                return $false
            }
            'no' {
                Write-Tell "Excluding inactive pairs."
                return $false
            }
            default {
                Write-ErrorLine "Invalid input. Please enter 'Yes' or 'No'."
            }
        }
    } while ($true)
}
# Check if the user wants to use default parameters
$useDefaultParameters = ChooseParameterMode

if ($useDefaultParameters) {
    $timerange = $defaultTimerange
    $timeframes = $defaultTimeframes
    $includeInactivePairs = $defaultIncludeInactivePairs
} else {
    # Get parameters from the user
    $timerange = Get-Timerange
    $timeframes = Get-Timeframes
    $includeInactivePairs = Get-IncludeInactivePairs
}

# Define the Docker command as a script block for easier reuse
$dockerCommand = {
    param($timerange, $timeframes, $includeInactivePairs)
    
    cd 'K:\Freqtrade\'
    $inactivePairsFlag = if ($includeInactivePairs) { "--include-inactive-pairs" } else { "" }
    $cmd = "docker-compose run --name DataDownload --rm freqtrade download-data --exchange kucoin --config user_data/config-1.json --data-format-ohlcv feather $inactivePairsFlag --prepend --timerange $timerange --timeframes $timeframes"
    Write-ActionLine "Running command: $cmd"
    Invoke-Expression $cmd
}
# Initially run the Docker command
& $dockerCommand -timerange $timerange -timeframes $timeframes -includeInactivePairs $includeInactivePairs
$exitLoop = $false
do {
    Write-ActionLine "Type 'retry' to use same parameters, 'new' to enter new parameters, or 'exit' to close this window"
    $input = Read-Host # Capture user input after displaying the message
    switch ($input) {
        'retry' {
            Write-Tell "Retrying with the same parameters..."
            & $dockerCommand -timerange $timerange -timeframes $timeframes -includeInactivePairs $includeInactivePairs
        }
        'new' {
            $useDefaultParameters = ChooseParameterMode
            if ($useDefaultParameters) {
                $timerange = $defaultTimerange
                $timeframes = $defaultTimeframes
                $includeInactivePairs = $defaultIncludeInactivePairs
            } else {
                $timerange = Get-Timerange
                $timeframes = Get-Timeframes
                $includeInactivePairs = Get-IncludeInactivePairs
            }
            Write-WarningLine "Running the Docker command with new parameters..."
            & $dockerCommand -timerange $timerange -timeframes $timeframes -includeInactivePairs $includeInactivePairs
        }
        'exit' {
            Write-InfoLine "Exiting..."
            break
        }
        default {
            Write-ErrorLine "Invalid input. Please type 'retry', 'new', or 'exit'."
        }
    }
} while ($true)
