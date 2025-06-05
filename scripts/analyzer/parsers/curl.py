import contextlib
import re
import json
import numpy as np
import utils.utils as utils


def get_info(data) -> list[dict]:
    results = []
    if not data:
        raise FileNotFoundError("No curl log file found!")
    results = parse_curl_log(data)
    return compute_stats(results)


def compute_metrics(stats: dict) -> dict:
    return {
        "min": float(np.min(stats)),
        "max": float(np.max(stats)),
        "mean": float(np.mean(stats)),
        "median": float(np.median(stats)),
        "std": float(np.std(stats)),
        "percentiles": {
            "25th": float(np.percentile(stats, 25)),
            "50th": float(np.percentile(stats, 50)),
            "75th": float(np.percentile(stats, 75)),
            "90th": float(np.percentile(stats, 90)),
            "95th": float(np.percentile(stats, 95)),
            "99th": float(np.percentile(stats, 99)),
        },
    }


def compute_stats(curl_logs: list[dict]) -> dict:
    latencies = [entry["latency"] for entry in curl_logs]
    total_times = [entry["total_time"] for entry in curl_logs]
    throughputs = [entry["throughput"] for entry in curl_logs]

    return {
        "latency": compute_metrics(latencies),
        "total_time": compute_metrics(total_times),
        "throughput": compute_metrics(throughputs),
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


def parse_curl_log(lines):
    results = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("URL:"):
            url = lines[i].strip().split("URL: ")[-1]
            latency = float(re.search(r"([\d.]+)", lines[i + 1]).group(1))
            total_time = float(re.search(r"([\d.]+)", lines[i + 2]).group(1))
            throughput = int(re.search(r"(\d+)", lines[i + 3]).group(1))

            results.append(
                {
                    "url": url,
                    "latency": latency,
                    "total_time": total_time,
                    "throughput": throughput,
                }
            )
            i += 4
        else:
            i += 1  # Skip malformed lines if any

    return results
