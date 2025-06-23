import json
import matplotlib.pyplot as plt
import pandas as pd

# Load the JSON file
with open("../../results/detailed_results.json") as f:
    data = json.load(f)

# Extract and flatten the data
records = []
for name, entry in data.items():
    print(f"Processing {name}")
    scheduler = entry["tor_params"]["scheduler"]
    print(json.dumps(entry["tor_params"], indent=2))
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

df = pd.DataFrame(records)

# Unique DP distributions
dp_distributions = df[~df["is_control"]]["distribution"].dropna().unique()


# Plotting function
def plot_metric_by_distribution(metric, dist, size):

    if size == "51200":
        sSize = "50 KiB"
    elif size == "1048576":
        sSize = "1 MiB"
    elif size == "5242880":
        sSize = "10 MiB"
    else:
        sSize = size

    plt.figure(figsize=(10, 6))

    subset = df[(df["distribution"] == dist) | (df["is_control"] == True)]

    for (sched, eps, dummy, file_size), group in subset.groupby(
        ["scheduler", "epsilon", "dummy", "filesize"]
    ):
        if file_size != size:
            continue
        group_sorted = group.sort_values("clients")
        label = f"{sched} | εD={dummy}" if eps != "control" else f"{sched} (control)"
        line_style = (
            "--" if sched == "DPKist" else "-" if sched == "DPVanilla" else ".-"
        )
        plt.plot(
            group_sorted["clients"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=line_style,
        )

    plt.title(f"{metric.capitalize()} vs Number of Clients ({sSize})")
    plt.xlabel("Number of Clients")
    plt.ylabel(metric.capitalize())
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"{metric}_vs_clients_{dist}.png")
    plt.show()


# Generate plots for each metric, for each DP distribution
for filesize in df["filesize"].unique():
    for metric in ["latency", "throughput", "jitter", "total_time"]:
        for dist in dp_distributions:
            plot_metric_by_distribution(metric, dist, filesize)
