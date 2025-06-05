import numpy as np
import json

def get_latency_metrics(test_results):
    pass

def get_throughput_metrics(test_results):
    pass

def get_jitter_metrics(circuits):
    pass

def merge_latency(keys, data):
    latencies = []
    for key in keys:
        if key in data:
            latencies.append(data[key].get("latency", {}))

    if not latencies:
        print("No latency data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}

    return {
        "mean": np.mean([d["mean"] for d in latencies]),
        "min": np.min([d["min"] for d in latencies]),
        "max": np.max([d["max"] for d in latencies]),
        "stddev": np.mean([d["std"] for d in latencies]),
        "median": np.mean([d["median"] for d in latencies])
    }


def merge_throughput(keys, data):
    throughputs = []
    for key in keys:
        if key in data:
            throughputs.append(data[key].get("throughput", {}))

    if not throughputs:
        print("No throughput data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}
    
    return {
        "mean": np.mean([d["mean"] for d in throughputs]),
        "min": np.min([d["min"] for d in throughputs]),
        "max": np.max([d["max"] for d in throughputs]),
        "stddev": np.mean([d["std"] for d in throughputs]),
        "median": np.mean([d["median"] for d in throughputs])
    }

def merge_jitter(keys, data):
    jitters = []
    for key in keys:
        if key in data:
            jitters.append(data[key].get("jitter", {}))

    if not jitters:
        print("No jitter data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}
    
    return {
        "mean": np.mean([d["mean"] for d in jitters]),
        "min": np.min([d["min"] for d in jitters]),
        "max": np.max([d["max"] for d in jitters]),
        "stddev": np.mean([d["deviation"] for d in jitters]),
        "variance": np.mean([d["variance"] for d in jitters])
    }

def merge_total_time(keys, data):
    total_times = []
    for key in keys:
        if key in data:
            total_times.append(data[key].get("total_time", {}))

    if not total_times:
        print("No total time data found for the provided keys.")
        return {"mean": 0, "min": 0, "max": 0, "stddev": 0}
    
    return {
        "mean": np.mean([d["mean"] for d in total_times]),
        "min": np.min([d["min"] for d in total_times]),
        "max": np.max([d["max"] for d in total_times]),
        "stddev": np.mean([d["std"] for d in total_times]),
        "median": np.mean([d["median"] for d in total_times])
    }