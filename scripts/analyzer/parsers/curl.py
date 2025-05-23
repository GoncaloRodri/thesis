
import contextlib
import utils.utils as utils

def get_info() -> list[dict]:

    filepaths = utils.get_curl_log_files()
    results = []
    if not filepaths:
        raise FileNotFoundError("No curl log files found!")
    for filepath in filepaths:
        if not filepath.endswith(".log"):
            raise ValueError(f"Invalid file format: {filepath}. Expected .log file.")
        parsed_data = parse(filepath)
        translated_data = translate(parsed_data)
        results.append(translated_data)

    return extract_overall_data(results)

def extract_overall_data(curl_logs: list[dict]) -> dict:
    total_bytes = sum(log.get("Throughput (bytes/s)", 0) for log in curl_logs)
    total_time = sum(log.get("Total time (s)", 0) for log in curl_logs)
    total_count = len(curl_logs)

    return {
        "total_bytes": total_bytes,
        "total_time (s)": total_time,
        "average_throughput (bytes/s)": total_bytes / total_count if total_count else 0,
        "average_latency (s)": sum(log.get("Latency (s)", 0) for log in curl_logs) / total_count if total_count else 0,
    }

def translate(curl_log: dict) -> dict:
    return {
        "Throughput (bytes/s)": curl_log.get("Download speed"),
        "Latency (s)": curl_log.get("Time to first byte"),
        "Total time (s)": curl_log.get("Total time"),
        "Start time (ns)": curl_log.get("Started at"),
        "End time (ns)": curl_log.get("Ended at"),
    }

def parse(filepath: str) -> dict:
    result = {}
    with open(filepath, 'r') as file:
        for line in file:
            if ':' in line:
                key, value = line.strip().split(':', 1)
                key = key.strip()
                value = value.strip()
                # Remove units like "s" and "bytes/sec", and convert to float or int if possible
                if value.endswith('s'):
                    value = float(value[:-1])
                elif value.endswith('bytes/sec'):
                    value = int(value.split()[0])
                else:
                    with contextlib.suppress(ValueError):
                        value = int(value)
                result[key] = value
    return result