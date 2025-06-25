import argparse
import os
import utils.utils as utils
import parsers.curl as curl_parser
import parsers.tor as tor_parser
import utils.metrics as metrics_utils
import json

# python3 main.py --dummy-ratio 50 --jitter-ratio 50 --clients 1 --nodes 3 --test-number 1 --file-size 1Mib


def resolve_files(test_path):
    info = {}
    curl = None
    tor = []

    info_path = os.path.join(test_path, "info.json")
    if os.path.isfile(info_path):
        with open(info_path, "r") as f:
            info = json.load(f)  #! WILL CRASH LOUDLY

    curl_path = os.path.join(test_path, "curl.log")
    if os.path.isfile(curl_path):
        with open(curl_path, "r") as f:
            curl = f.readlines()

    tor_folder = os.path.join(test_path, "tor")
    if os.path.isdir(tor_folder):
        for file_name in os.listdir(tor_folder):
            file_path = os.path.join(tor_folder, file_name)
            if os.path.isfile(file_path):
                abs_path = os.path.abspath(file_path)
                tor.append(abs_path)

    return info, curl, tor


def analyzer_data(info, curl_lines, tor_files):
    curl_data = {}
    tor_data = {}
    if curl_lines:
        curl_data = curl_parser.get_info(curl_lines)

    if tor_files:
        tor_data = tor_parser.get_info(tor_files)

    return info | curl_data | tor_data


def merge_data(test_data):
    data_per_test: dict[list] = {}
    for test_name, data in test_data.items():
        if data_per_test.get(data.get("name", test_name)):
            data_per_test[data.get("name", test_name)].append(test_name)
        else:
            data_per_test[data.get("name", test_name)] = [test_name]

    merged_data = {}

    for test_name, test_list in data_per_test.items():
        merged_data[test_name] = {
            "name": test_data[test_list[0]].get("name"),
            "file_size": test_data[test_list[0]].get("file_size"),
            "tor_params": test_data[test_list[0]].get("tor_params"),
            "client_params": test_data[test_list[0]].get("client_params"),
            "latency": metrics_utils.merge_latency(test_list, test_data),
            "throughput": metrics_utils.merge_throughput(test_list, test_data),
            "jitter": metrics_utils.merge_jitter(test_list, test_data),
            "total_time": metrics_utils.merge_total_time(test_list, test_data),
        }

    return merged_data

def resume_results_per_test(results):
    return {
        test_name: {
            "latency": test_results["latency"]["mean"],
            "throughput": test_results["throughput"]["mean"],
            "total_time": test_results["total_time"]["mean"],
            "jitter": test_results["jitter"]["mean"],
        }
        for test_name, test_results in results.items()
    }

def resume_results_per_metric(results):
    latency = {}
    throughput = {}
    total_time = {}
    jitter = {}

    for test_name, test_results in results.items():
        latency[test_name] = test_results["latency"]["mean"]
        throughput[test_name] = test_results["throughput"]["mean"]
        total_time[test_name] = test_results["total_time"]["mean"]
        jitter[test_name] = test_results["jitter"]["mean"]

    return {
        "latency": latency,
        "throughput": throughput,
        "total_time": total_time,
        "jitter": jitter,
    }


if __name__ == "__main__":

    test_results = {}

    main_folder = utils.get_main_folder()

    test_data = {}
    for test_folder_name in os.listdir(main_folder):
        test_path = os.path.join(main_folder, test_folder_name)

        info, curl, tor = resolve_files(test_path)

        test_data[test_folder_name] = analyzer_data(info, curl, tor)

    json.dump(
        test_data,
        open(os.path.join(main_folder, "../results/test_data.json"), "w"),
        indent=4,
    )

    test_results = merge_data(test_data)

    results_folder = os.path.join(main_folder, "../results")
    os.makedirs(results_folder, exist_ok=True)

    json.dump(
        test_results,
        open(os.path.join(results_folder, "../results/detailed_results.json"), "w"),
        indent=4,
    )

    json.dump(
        resume_results_per_test(test_results),
        open(os.path.join(results_folder, "../results/resumed_per_test.json"), "w"),
        indent=4,
    )

    json.dump(
        resume_results_per_metric(test_results),
        open(os.path.join(results_folder, "../results/resumed_per_metric.json"), "w"),
        indent=4,
    )

    print(
        "Test results have been saved to:",
        os.path.join(results_folder, "../results/test_results.json"),
    )
