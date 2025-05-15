import matplotlib.pyplot as plt
from datatypes import RelayData


def plot(data: dict[str, RelayData], test_name: str) -> None:
    """
    Plot the data for each relay and circuit.
    """
    circuits_legend = {}
    for name, relay_data in data.items():
        circuits_legend[name] = {}
        if len(relay_data["circuit_data"]) == 0:
            continue
        for n, (circ_id, circuit_data) in enumerate(
            relay_data["circuit_data"].items(), start=1
        ):

            circuits_legend[circ_id] = f"{name}-{n}"
            plot_deltas(
                relay=name,
                circ_id=f"{name}-{n}",
                test_name=test_name,
                deltas=circuit_data["deltas"],
            )

        plot_timestamps(
            relay=name,
            circuits=[
                f"{name}-{n}" for n in range(1, len(relay_data["circuit_data"]) + 1)
            ],
            test_name=test_name,
            timestamps=[
                circuit_data["timestamps"]
                for circuit_data in relay_data["circuit_data"].values()
            ],
            start_time=relay_data["start_time"],
        )

    return circuits_legend


def plot_deltas(
    relay,
    circ_id,
    test_name,
    deltas,
):
    plt.figure(figsize=(24, 6))
    plt.plot(
        list(range(len(deltas))),
        deltas,
        marker=".",
        linestyle="-",
        linewidth=0.4,
        markersize=1,
        alpha=0.7,
    )
    plt.yscale("log")
    plt.xlabel("Packet Sequence Number")
    plt.ylabel("Delta (ns)")
    plt.title(f"Packet Delta for Circuit {circ_id}")
    plt.grid(True, which="both", linestyle="", linewidth=0.1)
    plt.tight_layout()
    plt.savefig(f"plots/{test_name}/deltas.{circ_id}.png", format="png")
    plt.close()


def plot_timestamps(
    relay,
    circuits: list[str],
    test_name,
    timestamps: list[list[float]],
    start_time: float = 0,
):
    plt.figure(figsize=(24, 6))
    for i, ts in enumerate(timestamps):
        plt.scatter(
            list(range(len(ts))),
            [timestamp - start_time for timestamp in ts],
            marker=".",
            linestyle="-",
            linewidth=0.4,
            alpha=0.7,
            animated=True,
            label=circuits[i],
        )
    plt.xscale("linear")
    plt.xlabel("Packet Sequence Number")
    plt.ylabel("Timestamp (ns)")
    plt.title(f"Timestamp Overview for Relay {relay}")
    plt.legend()
    plt.grid(True, which="both", linestyle="", linewidth=0.1)
    plt.tight_layout()
    plt.savefig(f"plots/{test_name}/ts.{relay}.png", format="png")
    plt.close()


def plot_relays(info: dict, test_name: str) -> None:
    plt.figure(figsize=(10, 6))
    for i, (name, data) in enumerate(info.items()):
        f = 0
        for circ_n, circuit_data in data["circuit_data"].items():
            f += 0.1
            plt.scatter(
                x=circuit_data["timestamps"],
                y=[i+f]*len(circuit_data["timestamps"]),
                marker=".",
                linestyle="-", linewidth=0.2,
                alpha=0.7,
                label=name + " $ " + circ_n
            )
    plt.xlabel("Time")
    plt.ylabel("Node")
    plt.title("Packet Reception Times by Node")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"plots/relays/{test_name}-all.png", format="png")
    plt.close()


def plot_relay_circuits(
    circ_ids: list[str],
    ts: list[list[float]],
    name: str = "example",
    test_name: str = "test",
) -> None:
    plt.figure(figsize=(10, 6))
    for i, circ_id in enumerate(circ_ids):
        plt.scatter(
            x=ts[i],
            y=[i] * len(ts[i]),
            marker=".",
            linestyle="-",
            linewidth=0.2,
            alpha=0.7,
            label=circ_id,
        )

    plt.xlabel("Time")
    plt.ylabel("Node")
    plt.title(f"Packet Reception Times by Node {name}")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"plots/relay_circuits/{test_name}-{name}.png", format="png")
    plt.close()
