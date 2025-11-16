#!/usr/bin/env python
import os
import re
import glob
import subprocess
import sys

# =====================================================================================
# Default parameters (match your PowerShell script)
# =====================================================================================
DEFAULT_TIMERANGE = "20240101-20250601"
DEFAULT_USE_CACHE = False  # $false in PowerShell

# =====================================================================================
# Basic colored output (ANSI; works in modern Windows terminals)
# =====================================================================================
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


# =====================================================================================
# Paths
# =====================================================================================
EXPECTED_PATH = r"K:\Freqtrade"
CONFIG_FOLDER = "user_data"


def ensure_working_directory():
    if os.getcwd() != EXPECTED_PATH:
        write_warning_line(f"Switching to expected working directory: {EXPECTED_PATH}")
        try:
            os.chdir(EXPECTED_PATH)
        except Exception as e:
            write_error_line(f"Failed to change directory to {EXPECTED_PATH}. {e}")
            sys.exit(1)


# =====================================================================================
# Function to choose a backtest config (Select-BacktestOrder)
# =====================================================================================
def select_backtest_order():
    ensure_working_directory()

    config_folder_path = os.path.join(EXPECTED_PATH, CONFIG_FOLDER)
    if not os.path.isdir(config_folder_path):
        write_error_line(
            f"Directory '{CONFIG_FOLDER}' does not exist. Current path: {os.getcwd()}"
        )
        return None

    pattern = os.path.join(config_folder_path, "config-*.json")
    config_files = sorted(glob.glob(pattern))

    if not config_files:
        write_error_line(f"No config-*.json files found in '{CONFIG_FOLDER}'.")
        return None

    while True:
        write_action_line("Available Backtest Configs:")
        for index, cfg in enumerate(config_files, start=1):
            config_name = os.path.basename(cfg)
            # Extract config number from filename: config-3.json -> 3
            m = re.search(r"config-(\d+)\.json", config_name)
            config_number = m.group(1) if m else "X"
            container_name = f"Backtest_{config_number}"
            write_info_line(f"{index}. {container_name} with {config_name}")

        choice = input(f"Enter your choice (1-{len(config_files)}): ").strip()
        if choice.isdigit():
            idx = int(choice)
            if 1 <= idx <= len(config_files):
                chosen_path = config_files[idx - 1]
                config_name = os.path.basename(chosen_path)
                m = re.search(r"config-(\d+)\.json", config_name)
                config_number = m.group(1) if m else "X"
                container_name = f"Backtest_{config_number}"
                # Use relative path like PowerShell: "user_data/config-X.json"
                config_rel = f"{CONFIG_FOLDER}/{config_name}"
                return {
                    "ContainerName": container_name,
                    "ConfigFile": config_rel,
                }

        write_error_line(
            f"Invalid input. Please enter a number between 1 and {len(config_files)}."
        )


# =====================================================================================
# Docker command runner (equivalent to & $dockerCommand {..})
# =====================================================================================
def run_docker_command(
    container_name: str,
    timerange: str,
    use_cache: bool,
    disable_max_market_positions: bool,
    enable_position_stacking: bool,
    config_file: str,
):
    ensure_working_directory()

    # Cache option: same logic as PowerShell:
    # $cacheOption = if ($useCache) { "" } else { "--cache none" }
    cache_option = [] if use_cache else ["--cache", "none"]

    max_market_positions_option = (
        ["--disable-max-market-positions"] if disable_max_market_positions else []
    )
    position_stacking_option = (
        ["--enable-position-stacking"] if enable_position_stacking else []
    )

    cmd = [
        "docker-compose",
        "run",
        "--name",
        container_name,
        "--rm",
        "freqtrade",
        "backtesting",
        "--config",
        config_file,
        "--data-format-ohlcv",
        "feather",
        "--export",
        "trades",
        "--timerange",
        timerange,
    ] + cache_option + max_market_positions_option + position_stacking_option

    write_action_line("Running command: " + " ".join(cmd))

    try:
        subprocess.run(cmd, check=False)
    except Exception as e:
        write_error_line(f"Failed to run docker command: {e}")


# =====================================================================================
# Main flow (mirror your PowerShell MAIN SCRIPT START)
# =====================================================================================
def main():
    ensure_working_directory()

    backtest = select_backtest_order()
    if not backtest:
        write_error_line("No backtest option selected. Exiting...")
        return

    container_name = backtest["ContainerName"]
    config_file = backtest["ConfigFile"]

    timerange = DEFAULT_TIMERANGE
    use_cache = DEFAULT_USE_CACHE

    # Optional toggles, mirroring your script where they are effectively "off"
    disable_max_market_positions = False
    enable_position_stacking = False

    write_info_line(f"Selected Container: {container_name}")
    write_info_line(f"Config File: {config_file}")

    # Initial run
    run_docker_command(
        container_name,
        timerange,
        use_cache,
        disable_max_market_positions,
        enable_position_stacking,
        config_file,
    )

    # User input loop
    exit_loop = False
    while not exit_loop:
        write_action_line("Select 'retry' (r), 'new' (n), 'exit' (e)")
        user_input = input().strip().lower()

        if user_input == "retry":
            user_input = "r"
        elif user_input == "new":
            user_input = "n"
        elif user_input == "exit":
            user_input = "e"

        if user_input == "r":
            write_tell("Retrying with the same parameters...")
            run_docker_command(
                container_name,
                timerange,
                use_cache,
                disable_max_market_positions,
                enable_position_stacking,
                config_file,
            )

        elif user_input == "n":
            backtest = select_backtest_order()
            if not backtest:
                write_error_line("No backtest option selected. Exiting...")
                return

            container_name = backtest["ContainerName"]
            config_file = backtest["ConfigFile"]
            timerange = DEFAULT_TIMERANGE
            use_cache = DEFAULT_USE_CACHE
            # still keep the toggles "off" unless you want to add prompts later
            disable_max_market_positions = False
            enable_position_stacking = False

            write_info_line(f"Selected Container: {container_name}")
            write_info_line(f"Config File: {config_file}")

            write_warning_line("Running command with selected parameters...")
            run_docker_command(
                container_name,
                timerange,
                use_cache,
                disable_max_market_positions,
                enable_position_stacking,
                config_file,
            )

        elif user_input == "e":
            write_info_line("Exiting...")
            exit_loop = True

        else:
            write_error_line(
                "Invalid input. Select 'retry' (r), 'new' (n), or 'exit' (e)."
            )


if __name__ == "__main__":
    main()
