#!/bin/bash

source src/utils.sh

CONTAINERS=("client" "relay1" "relay2" "exit1")

exec_curl() {
    local url="$1"
    local log_file
    log_file=$(get_logfile "$2" "$3")

    log_info "Executing cURL command for URL: $url"
    curl --socks5 127.0.0.1:9000 -s -w "URL: $url\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null "$url" >>"$log_file"
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
    local tcpdump_mode="$4"
    local client_id="$5"
    shift 5
    local urls=("$@")

    for url in "${urls[@]}"; do
        if [[ -z "$url" ]]; then
            log_error "run_topwebclient()" "URL is empty, skipping..."
            continue
        fi
        start_tcpdump "$client_id" "$url"  "$tcpdump_mode"
        exec_curl "$url" "$client_id" "$name-$test_count" "$test_count"
        stop_tcpdump "${tcpdump_mode}"
    done
}

start_tcpdump() {
    if [[ "$3" ]]; then
        for container in "${CONTAINERS[@]}"; do
            start_tcpdump_on_relay "$container" "$1" "$2" &
        done
    fi
}

stop_tcpdump() {
    if [[ "$1" ]]; then
        for container in "${CONTAINERS[@]}"; do
            stop_tcpdump_on_relay "$container"
        done
    fi
}

start_tcpdump_on_relay() {
    local relay_name="$1"
    local client="$2"
    local id="$3"
    docker exec -d "thesis-${relay_name}-1" sh -c "(tcpdump -i eth0 -w /app/logs/wireshark/${relay_name}/${client}-${id}.pcap)"
}

stop_tcpdump_on_relay() {
    local relay_name="$1"
    docker exec -d "thesis-${relay_name}-1" sh -c "pkill tcpdump"
}


launch_topweb_clients() {
    echo "Launching top web clients..."
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    local test_timeout="$4"
    local top_web_clients="$5"
    local tcpdump_mode="$6"

    echo "Top web clients: $name with $top_web_clients clients, filesize: $filesize, test_count: $test_count, tcpdump_mode: $tcpdump_mode"

    local file_path="${CONFIG["absolute_path_dir"]}/${CONFIG["top_website_path"]}"

    echo "Launching top web clients for $name with $top_web_clients clients..."

    if [[ ! -f "$file_path" ]]; then
        log_fatal "fetch_topweb_urls()" "Top websites file not found: $file_path"
    fi
    echo "Fetching top websites from $file_path..."
    websites=()
    while IFS= read -r line; do
        websites+=("$line")
        echo -ne "Added URL: $line                      "\\r  
    done < "$file_path"

    if [[ ${#websites[@]} -eq 0 ]]; then
        log_fatal "launch_topweb_clients()" "No URLs found in the top websites file."
    fi

    log_info "Launching top $top_web_clients web clients for $name..."
    for ((k = 0; k < top_web_clients; k++)); do
        run_topwebclient "$name" "$filesize" "$test_count" "$tcpdump_mode" "$k" "${websites[@]}"  &
    done

    wait

    log_success "Top web clients for $name have completed."
}
