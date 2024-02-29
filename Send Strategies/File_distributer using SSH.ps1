# Define your bots and their details
$bots = @(
    @{ "name" = "name"; "ip" = "       "; "username" = "          "; "destination_dir" = "/home/.../Servers/Freqtrade/user_data/strategies" },
    @{ "name" = "name 2"; "ip" = "        "; "username" = "          "; "destination_dir" = "/home/.../Servers/Freqtrade/user_data/strategies" },
    @{ "name" = "name 3"; "ip" = "       "; "username" = "          "; "destination_dir" = "/home/.../Freqtrade/user_data/strategies" },
    @{ "name" = "name 4"; "ip" = "          "; "username" = "         "; "destination_dir" = "/home/..../Freqtrade/user_data/strategies" },
	  @{ "name" = "name 5"; "ip" = "            "; "username" = "          "; "destination_dir" = "/media/..../Space/user_data/strategies" }
)
$source_dir = "C:\Users\...\Freqtrade\user_data\strategies"
$strategy_distribution_file = "X:\...\...\strategy_distribution.json"

# Load strategy distribution from the JSON file
$strategy_distribution = Get-Content $strategy_distribution_file | ConvertFrom-Json

# Use default parameters
$useDefaults = $true
$defaultBotSelection = '-1' # Use '-1' for all bots
$defaultConfirmation = 'Y' # Use 'Y' for yes, 'N' for no

# Function to display bot choices and select multiple bots
function Select-Bots {
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $defaultSelection = ''
    )

    Write-Host "Available bots:"
    for ($i = 0; $i -lt $bots.Length; $i++) {
        Write-Host "$($i + 1): $($bots[$i].name)"
    }
    Write-Host "Enter '-1' to select all bots."

    if ($useDefaults -and $defaultSelection -eq '-1') {
        return $bots
    }

    $validSelection = $false
    [int[]]$selections = @()
    
    do {
        $input = Read-Host "Select bot(s) by number (e.g., 1,2 for multiple selections, -1 for all)"
        $trimmedInput = $input.Trim()
        $selections = $trimmedInput -split ' ' | ForEach-Object {
            $num = $_.Trim()
            if ($num -match '^\d+$' -and $num -gt 0 -and $num -le $bots.Length) {
                [int]$num
            } else {
                Write-Host "Invalid input: $_. Please enter valid bot numbers separated by spaces." -ForegroundColor Red
                return @()
            }
        }
        
        if ($selections.Count -gt 0) {
            $validSelection = $true
        } else {
            Write-Host "No valid selection made. Please enter valid bot numbers separated by spaces." -ForegroundColor Red
        }
    } while (-not $validSelection)
    
    return $selections | ForEach-Object { $bots[$_ - 1] }
}

# Function to copy strategies to the selected bot(s)
function Copy-Strategies {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $selectedBots
    )

    foreach ($bot in $selectedBots) {
        $botName = $bot.name
        $strategiesToCopy = $strategy_distribution.$botName

        if ($null -eq $strategiesToCopy -or $strategiesToCopy.Count -eq 0) {
            Write-Host "No strategies defined for $($bot.name) in the distribution file." -ForegroundColor Yellow
            continue
        }

        Write-Host "`nCopying strategies to $($bot.name) at $($bot.ip):"
        Write-Host "Destination Directory: $($bot.destination_dir)"
        Write-Host "Strategies to Copy:"
        $strategiesToCopy | ForEach-Object { Write-Host "    - $_" }

        foreach ($strategyName in $strategiesToCopy) {
            $local_path = Join-Path $source_dir $strategyName
            if (-Not (Test-Path $local_path)) {
                Write-Host "Strategy file not found: $local_path" -ForegroundColor Red
                $operationCompletedSuccessfully = $false
                continue
            }

            $remote_path = $bot.destination_dir + '/' + $strategyName

            # Construct and execute SCP command
            Write-Host "`nCopying $($strategyName) to $($bot.ip):$remote_path"
            $scp_command = "scp $local_path $($bot.username)@$($bot.ip):$remote_path"
            Invoke-Expression $scp_command
        }

        Write-Host "`nAll specified strategies have been successfully copied to $($bot.name).`n" -ForegroundColor Green
    }
}

do {
    try {
        $ErrorActionPreference = "Stop"
        $selectedBots = Select-Bots -defaultSelection $defaultBotSelection
        Copy-Strategies -selectedBots $selectedBots

        Write-Host "Operation completed successfully."
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }

    if (-not $useDefaults) {
        $continue = Read-Host "Do you want to select more bots? (Y/N)"
    } else {
        $continue = 'N'  # If using defaults, do not loop.
    }
} while ($continue -eq 'Y')

Read-Host -Prompt "Press Enter to exit"
