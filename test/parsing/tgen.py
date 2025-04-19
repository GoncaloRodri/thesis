def extract_tgen_info(server_file, client_file):
    with open(server_file, "r") as file:
        server_info = get_server_info(file)

    with open(client_file, "r") as file:
        client_info = get_client_info(file)

    print("Server Info:", server_info)
    print("Client Info:", client_info)
    return server_info, client_info


def get_server_info(file):
    fst_ts = None
    last_ts = None
    for line in file:
        if "[_tgenstream_changeSendState]" in line and fst_ts is None:
            fst_ts = line.split(" ")[2]
            continue

        if "[stream-success]" in line and fst_ts is not None:
            last_ts = line.split(" ")[2]
            break

    return {
        "first_ts": float(fst_ts),  # - 3600.0,
        "last_ts": float(last_ts),  # - 3600.0,
        "time_elapsed": float(last_ts) - float(fst_ts),
    }


def get_client_info(file):
    fst_ts = None
    last_ts = None
    for line in file:
        if "[_tgentransport_newHelper]" in line and fst_ts is None:
            fst_ts = line.split(" ")[2]
            continue

        if "[stream-success]" in line and fst_ts is not None:
            last_ts = line.split(" ")[2]
            break

    return {
        "first_ts": float(fst_ts),  # - 3600.0,
        "last_ts": float(last_ts),  # - 3600.0,
        "time_elapsed": float(last_ts) - float(fst_ts),
    }
