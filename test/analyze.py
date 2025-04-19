import plotting
import numpy as np


def generate_data(result, name):

    res = {}

    plotting.plot_relay_circuits(
        circ_ids=[circ_id for circ_id in result.keys()],
        ts=[
            list(map(lambda x: float(x[1]), data)) for data in result.values()
        ],
        name=name
    )

    res["circ_ids"] = [circ_id for circ_id in result.keys()]
    res["circuit_data"] = {}
    start_ts = None
    end_ts = None

    for circ_id, data in result.items():
        if len(data) == 0:
            print("No data for circ_id:", circ_id)
            continue

        if start_ts is None or float(data[0][1]) < start_ts:
            start_ts = float(data[0][1])

        if end_ts is None or float(data[-1][1]) > end_ts:
            end_ts = float(data[-1][1])

        deltas = []
        for i in range(1, len(data)):
            delta = float(data[i][1]) - float(data[i - 1][1])
            deltas.append(delta)

        max_delta = max(deltas)
        min_delta = min(deltas)
        avg_delta = sum(deltas) / len(deltas)

        plotting.plot_deltas(
            x=[i for i in range(len(deltas))],
            y=deltas,
            relay=name,
            circ_id=circ_id,
        )

        counts, bins = np.histogram(
            deltas
        )
        max_index = np.argmax(counts)
        most_common_delta = (bins[max_index] + bins[max_index + 1]) / 2

        res["circuit_data"][circ_id] = {
            "number_of_packets": len(data),
            "avg_delta": avg_delta,
            "min_delta": min_delta,
            "max_delta": max_delta,
            "most_common_delta": most_common_delta,
            "start_time": data[0][1],
            "end_time": data[-1][1],
            "total_time_elapsed": float(data[-1][1]) - float(data[0][1]),
            "deltas": deltas,
            "timestamps": [float(x[1]) for x in data],
        }

    res["start_time"] = start_ts
    res["end_time"] = end_ts
    res["total_time_elapsed"] = end_ts - start_ts
    res["total_number_of_packets"] = sum(
        [len(data) for data in result.values()]
    )
    res["total_number_of_circuits"] = len(result)
    return res
