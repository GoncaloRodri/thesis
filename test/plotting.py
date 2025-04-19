import matplotlib.pyplot as plt


def plot_relays(info: dict) -> None:
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
    plt.savefig("plots/relays/all.png", format="png")


def plot_relay_circuits(
    circ_ids: list[str],
    ts: list[list[float]],
    name: str = "example"
) -> None:
    plt.figure(figsize=(10, 6))
    for i, circ_id in enumerate(circ_ids):
        plt.scatter(
            x=ts[i],
            y=[i] * len(ts[i]),
            marker=".",
            linestyle="-", linewidth=0.2,
            # markersize=2,
            alpha=0.7,
            label=circ_id
        )

    plt.xlabel("Time")
    plt.ylabel("Node")
    plt.title("Packet Reception Times by Node")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("plots/relay_circuits/" + name + ".png", format="png")


def plot_deltas(x, y, relay="example", circ_id="example"):
    plt.figure(figsize=(24, 6))
    plt.plot(
        x,
        y,
        marker=".",
        linestyle="-", linewidth=0.2,
        markersize=2,
        alpha=0.7,
        color="blue"
    )
    plt.yscale("log")
    plt.xlabel("Packet Sequence Number")
    plt.ylabel("Delta (ns)")
    plt.title(f"Packet Delta for Circ ID {circ_id}")
    plt.grid(True, which="both", linestyle="", linewidth=0.5)
    plt.tight_layout()
    plt.savefig("plots/relays/" + relay + "/" + circ_id + ".png", format="png")
