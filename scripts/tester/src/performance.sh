#!/bin/bash

# shellcheck disable=SC1091
source src/utils.sh
# shellcheck disable=SC1091
source src/build.sh

DOCKER_COMPOSE_FILE="curl.docker-compose.yml"

get_url() {
    echo http://ipv4.download.thinkbroadband.com/"$1".zip
}

get_logfile() {
    local logfile="${CONFIG["absolute_path_dir"]}/tmp/curl/${1}_${2}_${3}.log"
    echo "$logfile"
}

run_performance_experiment() {
    local repeat
    repeat=${CONFIG["repeat"]}
    for ((i = 0; i < $((repeat)); i++)); do
        local name="$1"
        local params="$2"

        # Run the performance experiment
        log_info "Launching '$name-$i'"

        log_info "Cleaning up Docker containers and images..."
        docker_clean
        log_success "Docker cleanup Completed!\n"

        log_info "Setting up Torrc Configuration..."
        set_configuration "$params"
        log_success "Torrc Configuration Completed!\n"

        log_info "Launching Virtual Tor Network..."
        launch_tor_network "${CONFIG["absolute_path_dir"]}/${DOCKER_COMPOSE_FILE}"
        log_success "Virtual Tor Network Launched!\n"

        log_info "Starting Performance Experiment..."
        clients=$(echo "$params" | jq -r '.nclients')
        filesize=$(echo "$params" | jq -r '.filesize')
        launch_curl_clients "$name" "$clients" "$filesize" "$i"
        log_success "Performance Experiment Successful!\n"

        log_info "Extracting Results..."
        local dummy jitter nodes
        dummy=$(echo "$params" | jq -r '.dummy')
        jitter=$(echo "$params" | jq -r '.jitter')
        nodes=$(echo "$params" | jq -r '.nnodes')

        extract_results "$dummy" "$jitter" "$clients" "$nodes" "$filesize" "$i"
        log_success "Results Extraction Completed!\n"
        log_success "Performance Experiment '$name-$i' Completed!\n"
        sleep 1

        if [ "${CONFIG["copy_logs"]}" = true ]; then
            logs_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}"
            copy_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["copy_target"]}/$name-$i"
            log_info "Copying logs to ${copy_dir}"
            mkdir -p "${CONFIG["absolute_path_dir"]}/${CONFIG["copy_target"]}"
            cp -r "${logs_dir}" "${copy_dir}"
            log_success "Logs copied to ${copy_dir}\n"
            rm -rf "${logs_dir}*"
        fi

    done
}

exec_curl() {
    local url="$1"
    local log_file="$2"
    log_info "Executing cURL command for URL: $url"
    curl --socks5 127.0.0.1:9000 -w "Time to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -s -o /dev/null "$url" >>"$log_file" || log_error "cURL command failed" "Check the log file: $log_file"
}

launch_curl_clients() {
    local test_name="$1"
    local nclients="$2"
    local filesize="$3"
    local url

    url=$(get_url "$filesize")
    log_info "Launching $nclients cURL clients to download $filesize MB file from $url"

    for ((j = 0; j < nclients; j++)); do
        local log_file
        log_file=$(get_logfile "$test_name" "$filesize" "$j")
        exec_curl "$url" "$log_file" &
    done

    wait
}

extract_results() {
    cd "${CONFIG["absolute_path_dir"]}"/scripts/analyzer || exit 1
    local results_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["results_dir"]}performance"
    mkdir -p "$results_dir"
    log_info "Extracting results to $results_dir"
    local date
    date="$(date +%d%H%M)"
    python3 main.py \
        --dummy-ratio "$1" \
        --jitter-ratio "$2" \
        --clients "$3" \
        --nodes "$4" \
        --file-size "$5" \
        --test-number "$6" \
        >"$results_dir/${1}_${2}_${3}_${4}_${5}_${date}.json"

}
