#!/bin/bash

exec_curl() {
    local url="$1"
    local log_file="$2"
    local client="${3}"
    curl --socks5 127.0.0.1:"$client" -s -w "URL: $url\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null "$url" >>"$log_file"
}
get_url() {
    local filesize="$1"
    echo "https://httpbin.org/bytes/${filesize}"
}

get_logfile() {

    local logfile="${CONFIG["absolute_path_dir"]}/backup/${1}-${2}/curl.log"

    echo "$logfile"
}

run_webclient() {
    local url
    local log_file="$1"
    local filesize="$2"

    items=${CONFIG["clients"]}
    webcount=0
    length=${#items[@]}

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        current_item="${items[$((webcount % length))]}"
        sleep $((RANDOM % 30 + 1))
        counter=$((counter + 1))
        exec_curl "$url" "$log_file" "$current_item"
        ((webcount++))
    done
}

run_bulkclient() {
    local url
    local log_file="$1"
    local filesize="$2"

    items=${CONFIG["clients"]}
    bulkcount=0
    length=${#items[@]}

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        current_item="${items[$((bulkcount % length))]}"
        counter=$((counter + 1))
        exec_curl "$url" "$log_file" "$current_item"
        ((bulkcount++))
        sleep 0.5
    done
}
