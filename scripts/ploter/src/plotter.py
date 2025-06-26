import matplotlib.pyplot as plt

def plot_dummy(metric, filesize, data, show=False):
    print(data)
    for (sched, eps, dummy, file_size), group in data.groupby(
        ["scheduler", "epsilon", "dummy", "filesize"]
    ):
        if file_size != filesize or eps != "0":
            continue
        group_sorted = group.sort_values("clients")
        label = f"{sched} | εD={dummy}" if eps != "control" else f"{sched} (control)"
        line_style = "--" if sched == "DPKist" else "-" if sched == "DPVanilla" else ":"
        print(group_sorted[metric])

        plt.plot(
            group_sorted["clients"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=line_style,
        )
    plt.title(f"{metric.capitalize()} vs Number of Clients ({get_file_sizes(filesize)})")
    plt.xlabel("Number of Clients")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"figures/dummy/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(" ", "_")}.png")
    if show:
        plt.show()
    plt.clf()


def plot_jitter_by_distribution(metric, dist, filesize, data, show=False):
    for (sched, eps, dummy, file_size), group in data.groupby(
        ["scheduler", "epsilon", "dummy", "filesize"]
    ):
        if file_size != filesize or dummy != "0":
            continue
        group_sorted = group.sort_values("clients")
        label = f"{sched} | εS={eps}" if eps != "control" else f"{sched} (control)"
        line_style = "--" if sched == "DPKist" else "-" if sched == "DPVanilla" else ":"
        plt.plot(
            group_sorted["clients"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=line_style,
        )
    plt.title(f"{metric.capitalize()} vs Number of Clients ({get_file_sizes(filesize)})")
    plt.xlabel("Number of Clients")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"figures/jitter/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}_{dist}.png")
    if show:
        plt.show()
    plt.clf()

def plot_jitter(metric, filesize, data, accepted_eps, show=False):
    for (sched, eps, dummy, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "dummy", "filesize", "distribution"]
    ):
        if file_size != filesize or dummy != "0" or eps not in accepted_eps:
            continue
        group_sorted = group.sort_values("clients")
        label = f"{sched} | εS={eps} | {dist.capitalize()}" if eps != "control" else f"{sched} (control)"
        line_style = "--" if sched == "DPKist" else "-" if sched == "DPVanilla" else ":"
        plt.plot(
            group_sorted["clients"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=line_style,
        )
    plt.title(f"{metric.capitalize()} vs Number of Clients ({get_file_sizes(filesize)})")
    plt.xlabel("Number of Clients")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"figures/jitter/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}.png")
    if show:
        plt.show()
    plt.clf()


def plot_jitter_dummy(metric, filesize, data, accepted_dummy, accepted_eps, show=False):
    for (sched, eps, dummy, file_size, dist), group in data.groupby(
        ["scheduler", "epsilon", "dummy", "filesize", "distribution"]
    ):
        if file_size != filesize or eps not in accepted_eps or dummy not in accepted_dummy:
            continue
        group_sorted = group.sort_values("clients")
        label = f"{sched} | εD={dummy} | εS={eps} | {dist.capitalize()}" if eps != "control" else f"{sched} (control)"
        line_style = "--" if sched == "DPKist" else "-" if sched == "DPVanilla" else ":"
        plt.plot(
            group_sorted["clients"],
            group_sorted[metric],
            marker="o",
            label=label,
            linestyle=line_style,
        )
    plt.title(f"{metric.capitalize()} vs Number of Clients ({get_file_sizes(filesize)})")
    plt.xlabel("Number of Clients")
    plt.ylabel(get_units(metric))
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"figures/jitter_dummy/{metric}_vs_clients_{get_file_sizes(filesize).lower().replace(' ', '_')}.png")
    if show:
        plt.show()
    plt.clf()

########################################
# Helpers
########################################
def get_units(metric):
    if metric == "latency":
        return "Latency (s)"
    elif metric == "throughput":
        return "Throughput (bytes/s)"
    elif metric == "jitter":
        return "Jitter (s)"
    elif metric == "total_time":
        return "Total time (s)"
    else:
        return metric

def get_file_sizes(size):
    if size == "51200":
        return "50 KiB"
    elif size == "1048576":
        return "1 MiB"
    elif size == "5242880":
        return "10 MiB"
    else:
        return size
