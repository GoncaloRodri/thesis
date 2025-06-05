import yaml
import os

def get_config():
    with open("config.yaml", "r") as file:
        return yaml.safe_load(file)


def get_main_folder() -> str:
    """
    Get the main folder path from the configuration file.

    Returns:
        str: Path to the main folder.
    """
    return get_config()["logs_dir"]


def get_outliers_num_packers() -> int:
    """
    Get the number of outliers packets from the configuration file.

    Returns:
        int: Number of outliers packets.
    """
    return get_config()["outliers_num_packets"]

def get_tor_log_files() -> list:
    tor_folder = get_config()["tor_logs_folder"]
    return [os.path.join(tor_folder, f) for f in os.listdir(tor_folder) if os.path.isfile(os.path.join(tor_folder, f))]

def get_curl_log_files() -> list:
    """
    Get the curl log file path based on the test name.

    Args:
        test_name (str): Name of the test.

    Returns:
        str: Path to the curl log file.
    """
    curl_folder = get_config()["curl_logs_folder"]
    return [os.path.join(curl_folder, f) for f in os.listdir(curl_folder) if os.path.isfile(os.path.join(curl_folder, f))]

def get_test_name(
    size: str,
    dummy_ratio: str,
    jitter_ratio: str,
    clients: str,
    servers: str,
    test_number: str,
) -> str:
    """
    Generate a test name based on the provided parameters.

    Args:
        size (str): Size of the test.
        dummy_ratio (str): Ratio of dummy data.
        jitter_ratio (str): Ratio of jitter.
        clients (str): Number of clients.
        servers (str): Number of servers.
        test_number (str): Test number.

    Returns:
        str: Generated test name.
    """
    return f"{size}_dummy-{dummy_ratio}_jitter-{jitter_ratio}_clients-{clients}_servers-{servers}_{test_number}"
