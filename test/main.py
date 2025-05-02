from collections import defaultdict
import parsing.tgen as tgen
import parsing.tor as tor
from analyze import generate_data
import plotting
import json
import argparse


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Parse and analyze Tor logs.")
    parser.add_argument(
        "--test",
        type=str,
        default="test",
        help="Name of the test to be used for saving results.",
    )
    parser.add_argument(
        "-f",
        action="store_true",
        help="Filter the logs to only include the time between the first and last packet.",
    )
    args = parser.parse_args()

    test_name = args.test or "unknown"

    tgen_client_file = "../logs/tgen/client.tgen.log"
    tgen_server_file = "../logs/tgen/server.tgen.log"
    tgen_server_info, tgen_client_info = tgen.extract_tgen_info(
        tgen_server_file, tgen_client_file
    )

    files = [
        ("../logs/tor/exit1.tor.log", "exit1"),
        ("../logs/tor/relay1.tor.log", "relay1"),
        ("../logs/tor/relay2.tor.log", "relay2"),
        ("../logs/tor/client.tor.log", "client"),
        ("../logs/tor/authority.tor.log", "authority"),
        ("../logs/tor/hidden_service.tor.log", "hidden_service"),
    ]

    final_result = defaultdict(dict)

    # Replace with the path to your text fil
    for file_path, name in files:
        result = tor.parse_tor_log(
            file_path,
            start_time=tgen_client_info["first_ts"],
            end_time=tgen_client_info["last_ts"],
            filter=args.f,
        )
        if len(result) == 0:
            continue
        final_result[name] = generate_data(result, name, test_name)

        json_res = json.dumps(final_result[name], indent=2)
        with open(f"results/{name}.json", "w") as json_file:
            json_file.write(json_res)

    with open("results/all.json", "w") as json_file:
        json_file.write(json.dumps(final_result, indent=2))

    # Print and plot each relay circuit all together,
    # with timestamps as x-axis and assing a y value to each circuit
    plotting.plot_relays(final_result, test_name)

    print("Done!")
    print("Results saved in results/ folder.")
    print("Plots saved in plots/ folder.")
    print(
        "Total time elapsed:",
        tgen_client_info["last_ts"] - tgen_client_info["first_ts"],
    )

    for name, data in final_result.items():
        print(f"{name}:")
        print(
            "\tTotal time elapsed:",
            data["end_time"] - data["start_time"],
        )
        print("\tNumber of circuits:", len(data["circuit_data"]))
