def extract_tgen_info(server_file, client_file):
    with open(server_file, "r") as file:
        server_info = get_server_info(file)

    with open(client_file, "r") as file:
        client_info = get_server_info(file)

    print("Server Info:", server_info)
    print("Client Info:", client_info)
    return server_info, client_info


def get_server_info(file):
    fst_ts = None
    last_ts = None
    for line in file:
        if "[stream-status]" in line:
            fst_ts = line.split(" ")[2]
            continue

        if "[stream-success]" in line:
            if fst_ts is None:
                raise ValueError(
                    "No stream status found before stream success."
                )
            last_ts = line.split(" ")[2]
            break

    return {
        "first_ts": fst_ts,
        "last_ts": last_ts,
        "time_elapsed": float(last_ts) - float(fst_ts),
    }
