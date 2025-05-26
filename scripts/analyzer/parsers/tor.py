from collections import defaultdict
import utils.utils as utils
import utils.math as math_utils
import math
import json

def get_info(start_time=None, end_time=None):
    tor_log_files = utils.get_tor_log_files()
    if not tor_log_files:
        raise FileNotFoundError("No Tor log files found!")
    all_circuits_info = []
    for filepath in tor_log_files:
        if not filepath.endswith(".log"):
            raise ValueError(f"Invalid file format: {filepath}. Expected .log file.")
        data = parse_log(filepath)
        all_circuits_info.extend(extract_circuits_data(sort_data(data)))
    return extract_overall_data(all_circuits_info)


def extract_overall_data(circuits):
    total_packets = math_utils.get_sum(c["num_packets"] for c in circuits)
    
    if total_packets == 0:
        raise ValueError("Total number of packets is zero. Cannot compute statistics.")

    overall_min = math_utils.get_min(c["min_jitter"] for c in circuits)
    overall_max = math_utils.get_max(c["max_jitter"] for c in circuits)
    overall_mean = math_utils.get_sum(c["mean_jitter"] * c["num_packets"] for c in circuits) / total_packets
    overall_variance = math_utils.get_sum(
        (c["num_packets"] - 1) * c["variance_jitter"] + 
        c["num_packets"] * ((c["mean_jitter"] - overall_mean) ** 2)
        for c in circuits
    ) / (total_packets - 1)
    overall_deviation = math.sqrt(overall_variance)


    total_dummys = math_utils.get_sum(c["dummy_packets"] for c in circuits)
    dummy_ratio = total_dummys / total_packets * 100


    return {
        "total_packets": total_packets,
        "min_jitter": overall_min,
        "max_jitter": overall_max,
        "mean_jitter": overall_mean,
        "variance_jitter": overall_variance,
        "deviation_jitter": overall_deviation,
        "dummy_ratio": dummy_ratio,
        "total_dummys": total_dummys,
    }

def extract_circuits_data(data):
    circuit_data = []
    for circ_id, entries in data.items():
        if len(entries) <= utils.get_outliers_num_packers():
            continue
        dummy_data = 0
        deltas = []
        for i in range(1, len(entries)):
            deltas.append(float(entries[i][1]) - float(entries[i - 1][1]))
            dummy_data += 1 if entries[i][0] == "dummy" else 0
        
        circuit_data.append(
            {
                "mean_jitter": math_utils.get_mean(deltas),
                "max_jitter": math_utils.get_max(deltas),
                "min_jitter": math_utils.get_min(deltas),
                "variance_jitter": math_utils.get_variance(deltas),
                "deviation_jitter": math_utils.get_std_deviation(deltas),
                "num_packets": len(entries),
                "dummy_packets": dummy_data,
            }
        )
    return circuit_data

def parse_log(filepath):
    parsed_data = parse_file(filepath)
    return sort_data(parsed_data)

def parse_file(file):
    parsed_data = defaultdict(list)
    with open(file) as f:
        for line in f:
            if info := parse_line(line):
                circid, cmd, ts, direction = info
                parsed_data[circid].append((cmd, ts, direction))
    return parsed_data

def parse_line(line):
    if "RECEIVED CELL:" not in line:
        return None
    ts = parse_info(line, "time=", "\n") if "time=" in line else None
    cmd = parse_info(line, "command=", ", ") if "command=" in line else None
    circid = parse_info(line, "circ_id=", ", ") if "circ_id=" in line else None

    return (circid, cmd, ts, "") if circid and ts and cmd else None

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
    return dict(
        sorted(
            parsed_data.items(), key=lambda item: len(item[1]),
            reverse=True
        )
    )
