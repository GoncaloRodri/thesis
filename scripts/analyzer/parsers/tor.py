from collections import defaultdict
import utils.utils as utils
import utils.math as math_utils
import math
import json


def get_info(tor_log_files):
    relays = []
    for filepath in tor_log_files:
        if not filepath.endswith(".log"):
            raise ValueError(f"Invalid file format: {filepath}. Expected .log file.")
        data = parse_log(filepath)
        relays.extend(extract_circuits_data(data, filepath))

    return compute_stats(relays)


def compute_stats(relays):
    total_packets = math_utils.get_sum(r["num_packets"] for r in relays)

    if total_packets == 0:
        raise ValueError("Total number of packets is zero. Cannot compute statistics.")

    overall_min = math_utils.get_min(r["min_jitter"] for r in relays)
    overall_max = math_utils.get_max(r["max_jitter"] for r in relays)
    overall_mean = math_utils.get_sum(r["mean_jitter"] * r["num_packets"] for r in relays) / total_packets
    overall_variance = math_utils.get_sum(
        (r["num_packets"] - 1) * r["variance_jitter"] + 
        r["num_packets"] * ((r["mean_jitter"] - overall_mean) ** 2)
        for r in relays
    ) / (total_packets - 1)
    overall_deviation = math.sqrt(overall_variance)
    connections={}
    for r in relays:
        connections[r["filename"]] = r["connections"]
    return {
        "jitter": {
            "min": overall_min,
            "max": overall_max,
            "mean": overall_mean,
            "variance": overall_variance,
            "deviation": overall_deviation,
        },
        "total_packets": total_packets,
        "connections": connections,
    }


def extract_circuits_data(data, fs):
    relay_data = []
    connections = {}
    connections[data[0][0].split(":")[0]] = connections.get(data[0][0].split(":")[0], 0) + 1
    deltas = []
    last_ts = float(data[0][1])
    for i, (sender, ts) in enumerate(data, 1):
        deltas.append(float(ts) - last_ts)
        last_ts = float(ts)
        connections[sender.split(":")[0]] = connections.get(sender.split(":")[0], 0) + 1
    
    relay_data.append(
        {
            "filename": fs.split("/")[-1].replace(".tor.log", ""),
            "mean_jitter": math_utils.get_mean(deltas),
            "max_jitter": math_utils.get_max(deltas),
            "min_jitter": math_utils.get_min(deltas),
            "variance_jitter": math_utils.get_variance(deltas),
            "deviation_jitter": math_utils.get_std_deviation(deltas),
            "num_packets": len(data),
            "connections": connections,
        }
    )
    return relay_data

def parse_log(filepath):
    parsed_data = parse_file(filepath)
    return sort_data(parsed_data)

def parse_file(file):
    parsed_data = []
    with open(file) as f:
        for line in f:
            if info := parse_line(line):
                sender, ts = info
                parsed_data.append((sender, ts))
    return parsed_data

def parse_line(line):
    if "TLS_RECEIVED:" not in line:
        return None
    ts = parse_info(line, "time=", ", ") if "time=" in line else None
    sender = parse_info(line, "from=", " ") if "from=" in line else None

    return (sender, ts) if sender and ts else None

def parse_info(line, description, regex):
    start = (
        line.find(description) + len(description)
    )
    end = line.find(regex, start)
    return (
        line[start:end].strip()
        if end != -1
        else line[start:].strip()
    )

def sort_data(parsed_data):
    return sorted(parsed_data, key=lambda x: float(x[1]))
