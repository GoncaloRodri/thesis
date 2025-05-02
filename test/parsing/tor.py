from collections import defaultdict


def parse_tor_log(file_path, start_time=None, end_time=None, filter=False):
    print("Parsing file:", file_path)

    parsed_data = parse_file(file_path)

    filtered_data = filter_data(parsed_data, start_time, end_time, filter)

    sorted_data = sort_data(filtered_data)

    return sorted_data


def sort_data(parsed_data):
    return dict(
        sorted(
            parsed_data.items(), key=lambda item: len(item[1]),
            reverse=True
        )
    )


def parse_file(file):
    parsed_data = defaultdict(list)
    with open(file) as f:
        for line in f:
            info = parse_line(line)
            if info:
                circid, cmd, ts, direction = info
                parsed_data[circid].append((cmd, ts, direction))
    return parsed_data


def parse_line(line):
    if "RECEIVED CELL:" in line:
        ts = None
        cmd = None
        circid = None
        direction = None

        # Extract "circid="
        if "circ_id=" in line:
            circid = parse_info(line, "circ_id=", ", ")

        # Extract "ts="
        if "time=" in line:
            ts = parse_info(line, "time=", "\n")

        # Extract "command="
        if "command=" in line:
            cmd = parse_info(line, "command=", ", ")

        if "direction=" in line:
            direction = parse_info(line, "direction=", ",")

        if circid and ts and cmd and direction:
            return (circid, cmd, ts, direction)

        print("Incomplete line:", line)
        return None


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


def filter_data(parsed_data, start_time=None, end_time=None, has_time_filter=False):
    filtered_data = defaultdict(list)
    for circid, entries in parsed_data.items():
        if (
            len(entries) > 400
        ):
            cmd_filtered = commands_filter(entries)
            if (not has_time_filter) or time_filter(
                cmd_filtered, float(start_time), float(end_time + 1.0)
            ):
                filtered_data[circid] = cmd_filtered
    return filtered_data


def commands_filter(entries):
    filtered_entries = []
    for entry in entries:
        if entry[0] == "END":
            filtered_entries.append(entry)
    return filtered_entries


def time_filter(entries, start_time: float, end_time: float) -> bool:
    last_ts = float(entries[-1][1])
    first_ts = float(entries[0][1])

    if first_ts >= start_time and last_ts <= end_time:
        return True

    print("Time filter failed:")
    print("\tFirst timestamp:", entries[0])
    print(f"\t Circuit has early {start_time-first_ts} seconds")
    print(f"\t Circuit has late {last_ts-end_time} seconds")
    return False
