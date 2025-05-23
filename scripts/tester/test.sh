#!/bin/bash

set -eo pipefail

# shellcheck disable=SC1091
source src/utils.sh
# shellcheck disable=SC1091
source src/performance.sh

handle_args "$@"

verify_config

for experiment in "${EXPERIMENTS[@]}"; do
    experiment_name=$(echo "$experiment" | jq -r '.name')
    experiment_type=$(echo "$experiment" | jq -r '.type')
    experiment_params=$(echo "$experiment" | jq -c '.params')

    if [[ "$experiment_type" == "performance" ]]; then
        run_performance_experiment "$experiment_name" "$experiment_params"
    elif [[ "$experiment_type" == "unobservability" ]]; then
        log_warning "TODO"
    elif [[ "$experiment_type" == "resource_usage" ]]; then
        log_warning "TODO"
    else
        log_fatal "Experiment $experiment_name" "Unknown experiment type: $experiment_type"
    fi
    
done
