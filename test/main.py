from collections import defaultdict
import parsing.tgen as tgen


def extract_relay_timing_info(file_path):
    """
    Reads a text file, extracts lines containing "RELAY_TIMING",
    and retrieves the circuit ID (circid), timestamp (ts), and command (cmd)
    from each line.

    Args:
        file_path (str): Path to the text file.

    Returns:
        dict: A dictionary where keys are 'circid' and values
         are lists of (command, timestamp) pairs.
    """
    extracted_data = defaultdict(list)

    with open(file_path, 'r') as file:
        for line in file:
            if "RELAY_TIMING:" in line:
                ts = None
                cmd = None
                circid = None
                direction = None

                # Extract "circid="
                if "circ_id=" in line:
                    circid_start = line.find("circ_id=") + len("circ_id=")
                    circid_end = line.find(", ", circid_start)
                    circid = (
                        line[circid_start:circid_end]
                        if circid_end != -1
                        else line[circid_start:]
                    )

                # Extract "ts="
                if "time=" in line:
                    ts_start = line.find("time=") + len("time=")
                    ts_end = line.find(", ", ts_start)
                    ts = (
                        line[ts_start:ts_end]
                        if ts_end != -1
                        else line[ts_start:]
                    )

                # Extract "command="
                if "command=" in line:
                    cmd_start = line.find("command=") + len("command=")
                    cmd_end = line.find(", ", cmd_start)
                    cmd = (
                        line[cmd_start:cmd_end]
                        if cmd_end != -1
                        else line[cmd_start:]
                    )

                if "direction=" in line:
                    direction_start = (
                        line.find("direction=") + len("direction=")
                    )
                    direction_end = line.find(", ", direction_start)
                    direction = (
                        line[direction_start:direction_end]
                        if direction_end != -1
                        else line[direction_start:]
                    )

                # Append the (command, timestamp) pair
                # to the list for the given circid
                if circid and ts and cmd and direction:
                    extracted_data[circid].append((cmd, ts, direction))

    return extracted_data


def process_circuit(entries):

    deltas = []
    print("\tNumber of entries:", len(entries))
    minval = min(entries, key=lambda x: x[1])[1]
    maxval = max(entries, key=lambda x: x[1])[1]

    print("\tMin timestamp:", minval, "ns")
    print("\tMax timestamp:", maxval, "ns")
    print("\tTotal time elapsed:", int(maxval) - int(minval), "ns")
    # first_ts = entries[0][1]
    default_ts = minval
    max_delta = 0
    min_delta = float("inf")
    i = 1
    # print(
    #     "\tPacket nº | Command | Direction | Timestamp | Delta | Accumulated"
    # )

    for (cmd, ts, direction) in entries:
        # print(
        #     f"\t{i + 1} | {cmd} | {direction} | {ts} | "
        #     f"{int(ts) - int(default_ts)} ns | {int(ts) - int(first_ts)} ns"
        # )
        d = int(ts) - int(default_ts)
        deltas.append(d)

        if d > max_delta:
            max_delta = d
        if d < min_delta:
            min_delta = d

        default_ts = ts
        i += 1
    print("\tAverage Delta:", sum(deltas) / len(deltas), "ns")
    print("\tMax Delta:", max_delta, "ns")
    print("\tMin Delta:", min_delta, "ns")

    print("-" * 40)


# Example usage
if __name__ == "__main__":

    files = [
        "../logs/tor/authority.tor.log",
        "../logs/tor/relay1.tor.log",
        "../logs/tor/relay2.tor.log",
        "../logs/tor/exit1.tor.log",
    ]

    # Replace with the path to your text fil
    for file_path in files:
        print(f"Processing file: {file_path}")
        result = extract_relay_timing_info(file_path)
        filtered_result = {
            circid: entries
            for circid, entries in result.items()
            if len(entries) > 1
        }
        for circid, entries in filtered_result.items():
            print(f"Circuit ID: {circid}")
            circuit_info = process_circuit(entries)

    tgen_client_file = "../logs/client.tgen.log"
    tgen_server_file = "../logs/server.tgen.log"

    tgen_info = tgen.extract_tgen_info(tgen_server_file, tgen_client_file)
