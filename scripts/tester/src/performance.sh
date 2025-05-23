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
    local logfile="${CONFIG["logs_dir"]}curl_${1}_${2}_${3}.log"
    echo "$logfile"
}

run_performance_experiment() {
    local name="$1"
    local params="$2"


    # Run the performance experiment
    log_info "Launching '$name'"
    log "Parameters: $params"

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
    launch_curl_clients "$name" "$clients" "$filesize"
    log_success "Performance Experiment Successful!\n"
}

launch_curl_clients() {
    local test_name="$1"
    local nclients="$2"
    local filesize="$3"
    local url

    url=$(get_url "$filesize") 
    echo "URL: $url"
    log_info "Launching $nclients cURL clients to download $filesize MB file from $url"

    for ((i = 0; i < nclients; i++)); do
        local log_file
        log_file=$(get_logfile "$test_name" "$filesize" "$i")
        log_info "Launching cURL client $i"
        curl --socks5 127.0.0.1:9000 -w "Time to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null "$url" >> "$log_file" &
    done
    
    log "Waiting for cURL clients to finish"
    wait
}


