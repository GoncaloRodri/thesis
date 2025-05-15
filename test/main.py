import parsing.tgen as tgen
from analyze import analyze, get_summary
from plotting import plot
from save import save
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

    tgen_client_file = "../logs/tgen/simple-client.tgen.log"
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
    ]

    if test_name == "hidden_service":
        files.push(("../logs/tor/hidden_service.tor.log", "hidden_service"))

    analyzed_data = analyze(files, tgen_client_info)

    legend = plot(analyzed_data, test_name)

    save(
        analyzed_data,
        test_name,
    )

    summary = get_summary(legend, analyzed_data, test_name)

    save(summary, test_name)

    print("Done!")
    print(
        "Total time elapsed:",
        tgen_client_info["last_ts"] - tgen_client_info["first_ts"],
    )
