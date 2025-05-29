#!/bin/bash

source src/utils.sh

CONTAINERS=("client" "relay1" "relay2" "exit1")

exec_curl() {
    local url="$1"
    local log_file
    log_file=$(get_logfile "$2" "$3")

    log_info "Executing cURL command for URL: $url"
    curl --socks5 127.0.0.1:9000 -w "Time to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -f -s -o /dev/null "$url" >>"$log_file" || log_error "cURL command failed" "Check the log file: $log_file"
}
get_url() {
    local filesize="$1"
    echo "http://ipv4.download.thinkbroadband.com/${filesize}.zip"
}

get_logfile() {
    local logfile="${CONFIG["absolute_path_dir"]}/tmp/curl/${1}_${2}.log"
    echo "$logfile"
}

run_webclient() {
    local url
    local name="$1"
    local filesize="$2"
    local test_count="$3"

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        sleep $((RANDOM % 30 + 1))
        counter=$((counter + 1))
        exec_curl "$url" "$name" "$test_count"
    done
}

run_bulkclient() {
    local url
    local name="$1"
    local filesize="$2"
    local test_count="$3"

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        counter=$((counter + 1))
        exec_curl "$url" "$name" "$test_count"
        sleep 0.5
    done
}

launch_clients() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    local test_timeout="$4"
    local bulk_clients="$5"
    local web_clients="$6"
    local tcpdump_mode="$7"

    pids=()

    for ((k = 0; k < web_clients; k++)); do
        run_webclient "$name" "$filesize" "$test_count" "$tcpdump_mode" &
        pids+=($!)
    done

    for ((k = 0; k < bulk_clients; k++)); do
        run_bulkclient "$name" "$filesize" "$test_count" "$tcpdump_mode" &
        pids+=($!)
    done

    sleep "$test_timeout"
    log_info "Ending bulk clients for $name after $test_timeout seconds..."

    for pid in "${pids[@]}"; do
        kill -TERM "$pid" 2>/dev/null
    done

    log_success "All clients for $name have completed."
}

run_topwebclient() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    local urls="$4"

    log_info "Running top web client for $name..."
    for url in "${urls[@]}"; do
        start_tcpdump "$filesize" "$url"
        exec_curl "$url" "$name" "$test_count"
        stop_tcpdump
    done
}

start_tcpdump() {
    if [[ "$tcpdump_mode" ]]; then
        log_info "Starting tcpdump..."
        for container in "${CONTAINERS[@]}"; do
            start_tcpdump_on_relay "$container" "$1" "$2"
        done
    fi
}

stop_tcpdump() {
    if [[ "$tcpdump_mode" ]]; then
        log_info "Stopping tcpdump..."
        for container in "${CONTAINERS[@]}"; do
            stop_tcpdump_on_relay "$container"
        done
    fi
}

start_tcpdump_on_relay() {
    local relay_name="$1"
    local size="$2"
    local id="$3"
    docker exec -d "thesis-${relay_name}-1" sh -c "(tcpdump -i eth0 -w /app/logs/wireshark/${relay_name}/${size}-${id}.pcap)"
}

stop_tcpdump_on_relay() {
    local relay_name="$1"
    docker exec -d "thesis-${relay_name}-1" sh -c "pkill tcpdump"
}

fetch_topweb_urls() {
    local file_path="${CONFIG["absolute_path_dir"]}/${CONFIG["top_website_path"]}"

    if [[ ! -f "$file_path" ]]; then
        log_fatal "fetch_topweb_urls()" "Top websites file not found: $file_path"
    fi

    urls=()
    while IFS= read -r line; do
        urls+=("$line")
    done <"$file_path"
}

launch_topweb_clients() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    local test_timeout="$4"
    local top_web_clients="$5"
    local tcpdump_mode="$6"

    fetch_topweb_urls
    if [[ ${#urls[@]} -eq 0 ]]; then
        log_fatal "launch_topweb_clients()" "No URLs found in the top websites file."
    fi

    log_info "Launching top $top_web_clients web clients for $name..."
    for ((k = 0; k < top_web_clients; k++)); do
        run_topwebclient "$name" "$filesize" "$test_count" "$url" "$tcpdump_mode" &
    done

    wait

    log_success "Top web clients for $name have completed."
}
