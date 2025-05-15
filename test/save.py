import json


def save(data, test_name):

    with open(f"results/{test_name}_full.json", "w") as json_file:
        json_file.write(json.dumps(data, indent=2))

def save_summary(summary, test_name):
    with open(f"results/{test_name}_summary.json", "w") as json_file:
        json_file.write(json.dumps(summary, indent=2))
    