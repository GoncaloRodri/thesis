import argparse
import utils.utils as utils
import parsers.curl as curl
import parsers.tor as tor
import json

# python3 main.py --dummy-ratio 50 --jitter-ratio 50 --clients 1 --nodes 3 --test-number 1 --file-size 1Mib

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Run test with given parameters")
    parser.add_argument(
        "--dummy-ratio",
        type=int,
        required=True,
        help="Dummy traffic ratio (0-100)",
    )
    parser.add_argument(
        "--jitter-ratio",
        type=int,
        required=True,
        help="Jitter ratio (0-100)",
    )
    parser.add_argument('--clients', type=int, required=True, help='Number of clients')
    parser.add_argument('--nodes', type=int, required=True, help='Number of nodes')
    parser.add_argument('--test-number', type=int, required=True, help='Test number identifier')
    parser.add_argument('--file-size', required=True, help='Size of the test file')
    args = parser.parse_args()

    test_name = utils.get_test_name(
        args.file_size,
        args.dummy_ratio,
        args.jitter_ratio,
        args.clients,
        args.nodes,
        args.test_number
    )

    res = {
        "args": {
            "test_name": test_name,
            "curl_log_file": utils.get_curl_log_files(),
            "dummy_ratio": args.dummy_ratio,
            "jitter_ratio": args.jitter_ratio,
            "clients": args.clients,
            "nodes": args.nodes,
            "test_number": args.test_number,
            "file_size": args.file_size,
        }
    }

    curl_data = curl.get_info()

    jitter_data = {
        "jitter": tor.get_info()
    }

    res |= curl_data
    res |= (jitter_data)
    print(json.dumps(res, indent=4))
    with open(f"{test_name}.json", "w") as f:
        json.dump(res, f, indent=4)
