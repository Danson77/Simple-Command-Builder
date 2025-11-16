#!/usr/bin/env python
import os
import re
import glob
import subprocess
import sys

# =====================================================================================
# Basic colored output (works in modern Windows terminals with ANSI support)
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
# Config / path constants
# =====================================================================================
EXPECTED_PATH = r"K:\Freqtrade"
CONFIG_FOLDER = "user_data"
HYPEROPTS_FOLDER = r"K:\Freqtrade\user_data\hyperopts"


# =====================================================================================
# Helper: ensure working directory
# =====================================================================================
def ensure_working_directory():
    if os.getcwd() != EXPECTED_PATH:
        write_warning_line(f"Switching to expected working directory: {EXPECTED_PATH}")
        try:
            os.chdir(EXPECTED_PATH)
        except Exception as e:
            write_error_line(f"Failed to change directory to {EXPECTED_PATH}. {e}")
            sys.exit(1)


# =====================================================================================
# Function to choose a backtest config
# =====================================================================================
def get_config_file() -> str:
    ensure_working_directory()

    config_folder_path = os.path.join(EXPECTED_PATH, CONFIG_FOLDER)
    if not os.path.isdir(config_folder_path):
        write_error_line(
            f"Directory '{CONFIG_FOLDER}' does not exist. Current path: {os.getcwd()}"
        )
        sys.exit(1)

    pattern = os.path.join(config_folder_path, "config-*.json")
    configs = sorted(glob.glob(pattern))
    if not configs:
        write_error_line(f"No config-*.json files found in '{CONFIG_FOLDER}'.")
        sys.exit(1)

    while True:
        write_action_line("Available Backtest Configs:")
        for idx, cfg in enumerate(configs, start=1):
            config_name = os.path.basename(cfg)
            container_name = f"Backtest_{idx}"
            write_info_line(f"{idx}. {container_name} with {config_name}")

        choice = input(f"Enter your choice (1-{len(configs)}): ").strip()
        if choice.isdigit():
            index = int(choice)
            if 1 <= index <= len(configs):
                return configs[index - 1]

        write_error_line(f"Invalid input. Please enter a number between 1 and {len(configs)}.")


# =====================================================================================
# Function to get timerange input from the user
# =====================================================================================
def get_timerange() -> str:
    pattern = re.compile(r"^\d{8}-\d{8}$")
    while True:
        write_action_line(
            "Enter the timerange (format: YYYYMMDD-YYYYMMDD for example: 20240101-20250601 ):"
        )
        timerange = input().strip()
        if pattern.match(timerange):
            return timerange
        else:
            write_error_line(
                "Invalid input. Please enter the timerange in the format YYYYMMDD-YYYYMMDD."
            )


# =====================================================================================
# Function to get spaces input from the user
# =====================================================================================
def get_spaces() -> str:
    valid_spaces = [
        "all",
        "buy",
        "sell",
        "roi",
        "stoploss",
        "trailing",
        "trades",
        "protection",
        "default",
    ]

    while True:
        write_action_line("Choose spaces (can choose multiple, separated by space):")
        write_warning_line(
            "buy, sell, stoploss, trailing, roi, trades, protection, all, default"
        )
        spaces_input = input("Enter your choice: ").strip().lower()
        space_list = [s for s in spaces_input.split() if s]

        if not space_list:
            write_error_line("Invalid input. Please enter at least one space option.")
            continue

        if all(s in valid_spaces for s in space_list):
            # Return as original string (joined by single space)
            return " ".join(space_list)
        else:
            write_error_line(
                "Invalid input. Please enter valid space options separated by space (all lowercase)."
            )


# =====================================================================================
# Function to get the number of epochs from the user
# =====================================================================================
def get_epochs() -> int:
    while True:
        write_action_line("Enter the number of epochs (-e):")
        epochs = input().strip()
        if epochs.isdigit() and int(epochs) > 0:
            return int(epochs)
        else:
            write_error_line(
                "Invalid input. Please enter a positive integer for epochs."
            )


# =====================================================================================
# Function to get the number of workers from the user
# =====================================================================================
def get_workers() -> int:
    while True:
        write_action_line("Enter the number of workers:")
        workers = input().strip()
        if workers.isdigit() and int(workers) > 0:
            return int(workers)
        else:
            write_error_line(
                "Invalid input. Please enter a positive integer for workers."
            )


# =====================================================================================
# Function to get the hyperopt-loss type from the user
# =====================================================================================
def get_hyperopt_loss() -> str:
    while True:
        write_action_line("Choose the hyperopt-loss type:")
        write_warning_line("1:   Short Trade Duration      - Favors short trade times and avoiding losses.")
        write_warning_line("2:   Only Profit               - Focuses only on total profit.")
        write_warning_line("3:   Sharpe                    - Targets high Sharpe Ratio (return vs. volatility) on trade returns.")
        write_warning_line("4:   Sharpe Daily              - Same as Sharpe, but calculated on daily returns.")
        write_warning_line("5:   Sortino                   - Targets high Sortino Ratio (return vs. downside risk) on trade returns.")
        write_warning_line("6:   Sortino Daily             - Same as Sortino, but calculated on daily returns.")
        write_warning_line("7:   Max DrawDown              - Minimizes the largest account drop (max drawdown).")
        write_warning_line("8:   Max DrawDown Relative     - Minimizes both largest drop and relative drop size.")
        write_warning_line("9:   Calmar                    - Targets high Calmar Ratio (return vs. max drawdown).")
        write_warning_line("10:  Profit DrawDown           - Balances high profit with low drawdown.")
        write_warning_line("11: *List of Customs*          - Shows custom hyperopt loss functions.")
        choice = input("Enter your choice: ").strip()

        if choice == "1":
            return "ShortTradeDurHyperOptLoss"
        elif choice == "2":
            return "OnlyProfitHyperOptLoss"
        elif choice == "3":
            return "SharpeHyperOptLoss"
        elif choice == "4":
            return "SharpeHyperOptLossDaily"
        elif choice == "5":
            return "SortinoHyperOptLoss"
        elif choice == "6":
            return "SortinoHyperOptLossDaily"
        elif choice == "7":
            return "MaxDrawDownHyperOptLoss"
        elif choice == "8":
            return "MaxDrawDownRelativeHyperOptLoss"
        elif choice == "9":
            return "CalmarHyperOptLoss"
        elif choice == "10":
            return "ProfitDrawDownHyperOptLoss"
        elif choice == "11":
            write_tell("Custom hyperopt loss selected.")
            return "Custom"
        else:
            write_error_line("Invalid choice. Please enter a number between 1 and 11.")


# =====================================================================================
# Function to get the custom hyperopt loss class name from Python files
# =====================================================================================
def get_custom_hyperopt_loss(folder_path: str) -> str | None:
    write_action_line("Available custom hyperopt loss files:")

    pattern = os.path.join(folder_path, "*.py")
    loss_files = sorted(glob.glob(pattern))

    if not loss_files:
        write_error_line("No custom hyperopt loss files found in the specified folder.")
        return None

    for i, path in enumerate(loss_files, start=1):
        write_warning_line(f"{i}: {os.path.basename(path)}")

    choice_index_str = input(
        "Enter the number corresponding to custom hyperopt loss file: "
    ).strip()
    if not choice_index_str.isdigit():
        write_error_line(
            f"Invalid choice. Please enter a number between 1 and {len(loss_files)}."
        )
        return None

    choice_index = int(choice_index_str)
    if not (1 <= choice_index <= len(loss_files)):
        write_error_line(
            f"Invalid choice. Please enter a number between 1 and {len(loss_files)}."
        )
        return None

    chosen_file = loss_files[choice_index - 1]

    try:
        with open(chosen_file, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        write_error_line(f"Failed to read {chosen_file}: {e}")
        return None

    # Regex to find class XXX(IHyperOptLoss):
    m = re.search(
        r"class\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(IHyperOptLoss\):",
        content,
    )
    if not m:
        write_error_line(
            "Could not find a class inheriting from IHyperOptLoss in the selected file."
        )
        return None

    class_name = m.group(1)
    return class_name


# =====================================================================================
# Function to run the docker-compose hyperopt command
# =====================================================================================
def run_docker_command(
    timerange: str,
    spaces: str,
    epochs: int,
    workers: int,
    hyperopt_loss: str,
    config_file: str,
):
    ensure_working_directory()

    # Build docker command as list (safer), but print it as a single string
    spaces_list = [s for s in spaces.split() if s]

    cmd = [
        "docker-compose",
        "run",
        "--name",
        "Hyperopt",
        "--rm",
        "freqtrade",
        "hyperopt",
        "--config",
        config_file,
        "--data-format-ohlcv",
        "feather",
        "--random-state",
        "49125",
        "--timerange",
        timerange,
        "--spaces",
    ] + spaces_list + [
        "-e",
        str(epochs),
        "-j",
        str(workers),
        "--hyperopt-loss",
        hyperopt_loss,
    ]

    write_action_line("Running command: " + " ".join(cmd))

    try:
        subprocess.run(cmd, check=False)
    except Exception as e:
        write_error_line(f"Failed to run docker command: {e}")


# =====================================================================================
# Main flow
# =====================================================================================
def main():
    ensure_working_directory()

    # Initial prompts
    timerange = get_timerange()
    config_file = get_config_file()
    spaces = get_spaces()
    epochs = get_epochs()
    workers = get_workers()
    hyperopt_loss = get_hyperopt_loss()

    if hyperopt_loss == "Custom":
        custom_loss = get_custom_hyperopt_loss(HYPEROPTS_FOLDER)
        if custom_loss:
            hyperopt_loss = custom_loss
        else:
            write_error_line(
                "No custom loss selected or could not parse class. Please run again and choose correctly."
            )
            sys.exit(1)

    # Initial run
    run_docker_command(timerange, spaces, epochs, workers, hyperopt_loss, config_file)

    # Loop for user input
    while True:
        write_action_line(
            "Type 'retry' (or 'r') to use same parameters, "
            "'new' (or 'n') to enter new parameters, or "
            "'exit' (or 'e') to close this window"
        )
        user_input = input().strip().lower()

        # Normalize long commands to short ones
        if user_input == "retry":
            user_input = "r"
        elif user_input == "new":
            user_input = "n"
        elif user_input == "exit":
            user_input = "e"

        if user_input == "r":
            write_tell("Retrying with the same parameters...")
            run_docker_command(
                timerange, spaces, epochs, workers, hyperopt_loss, config_file
            )

        elif user_input == "n":
            # Prompt user again for all values
            timerange = get_timerange()
            config_file = get_config_file()
            spaces = get_spaces()
            epochs = get_epochs()
            workers = get_workers()
            hyperopt_loss = get_hyperopt_loss()

            if hyperopt_loss == "Custom":
                custom_loss = get_custom_hyperopt_loss(HYPEROPTS_FOLDER)
                if custom_loss:
                    hyperopt_loss = custom_loss
                else:
                    write_error_line(
                        "No custom loss selected or could not parse class. Please run again and choose correctly."
                    )
                    sys.exit(1)

            write_warning_line("Running command with new parameters...")
            run_docker_command(
                timerange, spaces, epochs, workers, hyperopt_loss, config_file
            )

        elif user_input == "e":
            write_info_line("Exiting...")
            break

        else:
            write_error_line("Invalid input. Please type 'retry', 'new', or 'exit'.")


if __name__ == "__main__":
    main()