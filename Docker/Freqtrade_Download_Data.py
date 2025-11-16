#!/usr/bin/env python
import os
import re
import subprocess
import sys

# ==============================
# Default parameters
# ==============================
DEFAULT_TIMERANGE = "20240101-20241100"
DEFAULT_TIMEFRAMES = "1m 5m 15m 1h"
DEFAULT_INCLUDE_INACTIVE_PAIRS = False

EXPECTED_PATH = r"K:\Freqtrade"

# ==============================
# Colored output helpers
# ==============================
RESET = "\033[0m"
RED = "\033[31m"
WHITE = "\033[37m"
YELLOW = "\033[33m"
GREEN = "\033[32m"
BLUE = "\033[34m"


def write_error_line(msg: str):
    print(f"{RED}{msg}{RESET}")


def write_info_line(msg: str):
    print(f"{WHITE}{msg}{RESET}")


def write_warning_line(msg: str):
    print(f"{YELLOW}{msg}{RESET}")


def write_action_line(msg: str):
    print(f"{GREEN}{msg}{RESET}")


def write_tell(msg: str):
    print(f"{BLUE}{msg}{RESET}")


# ==============================
# Ensure working directory
# ==============================
def ensure_working_directory():
    if os.getcwd() != EXPECTED_PATH:
        write_warning_line(f"Switching to expected working directory: {EXPECTED_PATH}")
        try:
            os.chdir(EXPECTED_PATH)
        except Exception as e:
            write_error_line(f"Failed to change directory to {EXPECTED_PATH}. {e}")
            sys.exit(1)


# ==============================
# Get-Timerange
# ==============================
def get_timerange() -> str:
    pattern = re.compile(r"^\d{8}-\d{8}$")
    while True:
        write_action_line("Enter the timerange (format: YYYYMMDD-YYYYMMDD):")
        timerange = input().strip()
        if pattern.match(timerange):
            return timerange
        else:
            write_error_line(
                "Invalid input. Please enter the timerange in the format YYYYMMDD-YYYYMMDD."
            )


# ==============================
# ChooseParameterMode
# ==============================
def choose_parameter_mode() -> bool:
    while True:
        write_warning_line("Do you want to use default parameters? (Yes/No):")
        choice = input().strip().lower()

        if choice in ("y", "yes"):
            write_tell("Default parameters selected.")
            return True
        elif choice in ("n", "no"):
            write_tell("Custom parameters selected.")
            return False
        else:
            write_error_line("Invalid input. Please enter 'Yes' or 'No'.")


# ==============================
# Get-Timeframes
# ==============================
def get_timeframes() -> str:
    allowed_timeframes = [
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "4h",
        "6h",
        "12h",
        "1d",
    ]

    while True:
        write_action_line(
            "Enter the Timeframes (separated by spaces, e.g., 1m 5m 15m 30m 1h 2h 4h 6h 12h 1d):"
        )
        user_input = input().strip().lower()
        input_timeframes = [t for t in user_input.split(" ") if t]

        if not input_timeframes:
            write_error_line("Invalid input. Please enter at least one timeframe.")
            continue

        all_valid = all(t in allowed_timeframes for t in input_timeframes)

        if all_valid:
            write_tell(
                "You've selected the timeframes: " + ", ".join(input_timeframes)
            )
            # Join with a single space, like in your PowerShell script
            return " ".join(input_timeframes)
        else:
            write_error_line(
                "Invalid input. Please enter valid timeframes separated by spaces. "
                f"Allowed: {', '.join(allowed_timeframes)}."
            )


# ==============================
# Get-IncludeInactivePairs
# ==============================
def get_include_inactive_pairs() -> bool:
    while True:
        write_warning_line("Do you want to include inactive pairs? (Yes/No)")
        choice = input().strip().lower()

        if choice in ("y", "yes"):
            write_tell("Including inactive pairs.")
            return True
        elif choice in ("n", "no"):
            write_tell("Excluding inactive pairs.")
            return False
        else:
            write_error_line("Invalid input. Please enter 'Yes' or 'No'.")


# ==============================
# Run Docker command
# ==============================
def run_docker_command(timerange: str, timeframes: str, include_inactive_pairs: bool):
    ensure_working_directory()

    inactive_flag = ["--include-inactive-pairs"] if include_inactive_pairs else []

    timeframes_list = [t for t in timeframes.split(" ") if t]

    cmd = [
        "docker-compose",
        "run",
        "--name",
        "DataDownload",
        "--rm",
        "freqtrade",
        "download-data",
        "--exchange",
        "kucoin",
        "--config",
        "user_data/config-1.json",
        "--data-format-ohlcv",
        "feather",
    ] + inactive_flag + [
        "--prepend",
        "--timerange",
        timerange,
        "--timeframes",
    ] + timeframes_list

    write_action_line("Running command: " + " ".join(cmd))

    try:
        subprocess.run(cmd, check=False)
    except Exception as e:
        write_error_line(f"Failed to run docker command: {e}")


# ==============================
# Main flow
# ==============================
def main():
    use_default = choose_parameter_mode()

    if use_default:
        timerange = DEFAULT_TIMERANGE
        timeframes = DEFAULT_TIMEFRAMES
        include_inactive_pairs = DEFAULT_INCLUDE_INACTIVE_PAIRS
    else:
        timerange = get_timerange()
        timeframes = get_timeframes()
        include_inactive_pairs = get_include_inactive_pairs()

    # Initial run
    run_docker_command(timerange, timeframes, include_inactive_pairs)

    # Loop
    while True:
        write_action_line(
            "Type 'retry' to use same parameters, 'new' to enter new parameters, or 'exit' to close this window"
        )
        inp = input().strip().lower()

        if inp == "retry":
            write_tell("Retrying with the same parameters...")
            run_docker_command(timerange, timeframes, include_inactive_pairs)

        elif inp == "new":
            use_default = choose_parameter_mode()
            if use_default:
                timerange = DEFAULT_TIMERANGE
                timeframes = DEFAULT_TIMEFRAMES
                include_inactive_pairs = DEFAULT_INCLUDE_INACTIVE_PAIRS
            else:
                timerange = get_timerange()
                timeframes = get_timeframes()
                include_inactive_pairs = get_include_inactive_pairs()

            write_warning_line("Running the Docker command with new parameters...")
            run_docker_command(timerange, timeframes, include_inactive_pairs)

        elif inp == "exit":
            write_info_line("Exiting...")
            break

        else:
            write_error_line("Invalid input. Please type 'retry', 'new', or 'exit'.")


if __name__ == "__main__":
    main()
