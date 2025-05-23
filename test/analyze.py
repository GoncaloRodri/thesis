import plotting
import numpy as np
import parsing.tor as tor
from datatypes import RawCircuitData, RelayData, CircuitData


def analyze(files, tgen_client_info) -> dict[str, RelayData]:
    analysis = {}
    for file_path, name in files:
        result = tor.parse_tor_log(
            file_path,
            start_time=tgen_client_info["first_ts"],
            end_time=tgen_client_info["last_ts"],
            filter=True,
        )
        if len(result) == 0:
            continue

        raw_data = collect(result)

        analysis[name] = generate_data(raw_data, name)

    if len(analysis) == 0:
        print("No data found in any of the files.")
        return None

    return analysis


# Collects simple and raw data from relays and circuits, ready to be transformed into useful data


def collect(result) -> list[RawCircuitData]:
    collect = []

    for circ_id, data in result.items():
        if len(data) == 0:
            continue

        dummy_data = 0

        deltas = []
        timestamps = []
        for i in range(1, len(data)):
            delta = float(data[i][1]) - float(data[i - 1][1])
            deltas.append(delta)
            timestamps.append(float(data[i][1]))
            if data[i][0] == "dummy":
                dummy_data += 1

        collect.append(
            {
                "id": circ_id,
                "deltas": deltas,
                "timestamps": timestamps,
                "number_of_packets": len(data),
                "start_time": data[0][1],
                "end_time": data[-1][1],
                "dummy_count": dummy_data,
            }
        )

    return collect


def generate_data(raw, name) -> RelayData:
    relay: RelayData = {}

    relay["name"] = name
    relay["start_time"] = float("inf")
    relay["end_time"] = float(0)
    relay["circuit_data"] = {}
    relay["dummy_count"] = 0

    for raw_circuit in raw:
        circ: CircuitData = {
            "id": raw_circuit["id"],
            "avg_delta": np.mean(raw_circuit["deltas"]),
            "min_delta": np.min(raw_circuit["deltas"]),
            "max_delta": np.max(raw_circuit["deltas"]),
            "num_packets": raw_circuit["number_of_packets"],
            "delta_variance": np.var(raw_circuit["deltas"]),
            "delta_deviation": np.std(raw_circuit["deltas"]),
            "total_elapsed_time": float(raw_circuit["end_time"])
            - float(raw_circuit["start_time"]),
            "dummy_count": raw_circuit["dummy_count"],
            "dummy_ratio": raw_circuit["dummy_count"]
            / raw_circuit["number_of_packets"],
            "deltas": raw_circuit["deltas"],
            "timestamps": raw_circuit["timestamps"],
        }

        relay["dummy_count"] += raw_circuit["dummy_count"]
        relay["circuit_data"][raw_circuit["id"]] = circ
        relay["start_time"] = (
            float(raw_circuit["start_time"])
            if float(raw_circuit["start_time"]) < float(relay["start_time"])
            else relay["start_time"]
        )
        relay["end_time"] = max(relay["end_time"], float(raw_circuit["end_time"]))

    relay["total_time_elapsed"] = float(relay["end_time"]) - float(relay["start_time"])
    relay["total_number_of_packets"] = sum(
        [circ["num_packets"] for circ in relay["circuit_data"].values()]
    )
    relay["dummy_ratio"] = relay["dummy_count"] / relay["total_number_of_packets"]

    return relay


def get_summary(legend, data, test_name, filesize=None) -> dict[str, RelayData]:
    """
    Get a summary of the data.
    """

    first = float("inf")
    last = float(0)
    num_packets = 0
    num_dummy = 0

    for relay, relay_data in data.items():
        first = min(first, float(relay_data["start_time"]))
        last = max(last, float(relay_data["end_time"]))
        num_packets += relay_data["total_number_of_packets"]
        num_dummy += relay_data["dummy_count"]

        for circuit_id, circuit_data in relay_data["circuit_data"].items():
            del circuit_data["deltas"]
            del circuit_data["timestamps"]

    data["circuits_legend"] = legend
    data["test_name"] = test_name
    data["start_time"] = first
    data["end_time"] = last
    data["total_time_elapsed"] = last - first
    data["total_number_of_packets"] = num_packets
    data["dummy_count"] = num_dummy
    data["dummy_ratio"] = num_dummy / num_packets

    if filesize:
        data["filesize"] = {
            "bytes": filesize,
            "Kb": filesize / 1024,
            "Mb": filesize / 1024 / 1024,
            "Gb": filesize / 1024 / 1024 / 1024,
        }

    return data
