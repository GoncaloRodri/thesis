import pandas as pd


def parse_detailed(data):
    records = []
    for name, entry in data.items():
        scheduler = entry["tor_params"]["scheduler"]
        is_control = not scheduler.startswith("DP")

        # Assign dummy values for control
        epsilon = entry["tor_params"].get("dp_epsilon", "control")
        if is_control:
            epsilon = "control"
            distribution = "CONTROL"
        else:
            distribution = entry["tor_params"]["dp_distribution"]

        clients = int(entry["client_params"]["bulk_clients"]) + int(entry["client_params"]["web_clients"])

        record = {
            "name": name,
            "scheduler": scheduler,
            "epsilon": str(epsilon),
            "distribution": distribution,
            "clients": clients,
            "latency": entry["latency"]["mean"],
            "throughput": entry["throughput"]["mean"],
            "jitter": entry["jitter"]["mean"],
            "total_time": entry["total_time"]["mean"],
            "is_control": is_control,
            "dummy": entry["tor_params"].get("dummy", False),
            "filesize": entry["file_size"],
        }
        if record["filesize"] != "5120":
            records.append(record)

    # Convert to DataFrame
    return records