#!/bin/bash

# shellcheck disable=SC1091
source src/utils.sh
source src/build.sh
source src/clients.sh

DOCKER_COMPOSE_FILE="docker-compose.yml"

run() {
    local repeat name tcpdump_mode end_test_at client_params tor_params

    repeat=${CONFIG["repeat"]}
    name="$1"
    tcpdump_mode="$2"
    file_size="$3"
    end_test_at="$4"
    client_params="$5"
    tor_params="$6"

    # Client Params
    bulk_clients=$(echo "$client_params" | jq -r '.bulk_clients')
    web_clients=$(echo "$client_params" | jq -r '.web_clients')
    top_web_clients=$(echo "$client_params" | jq -r '.top_web_clients')

    for ((i = 0; i < $((repeat)); i++)); do

        # Run the performance experiment
        log_info "Launching '$name-$i'"
        mkdir -p "${CONFIG["absolute_path_dir"]}/backup/$name-$i"

        log_info "Cleaning up Docker containers and images..."
        docker_clean
        log_success "Docker cleanup Completed!\n"

        log_info "Setting up Torrc Configuration..."
        set_configuration "$tor_params"
        log_success "Torrc Configuration Completed!\n"

        log_info "Launching Virtual Tor Network..."
        launch_tor_network "${CONFIG["absolute_path_dir"]}/${DOCKER_COMPOSE_FILE}"
        log_success "Virtual Tor Network Launched!\n"

        if [ -n "$top_web_clients" ] && [ "$top_web_clients" -gt 0 ]; then
            log_info "Starting Top Websites Clients Experiment..."
            launch_topweb_clients "$name" "$file_size" "$i" "$end_test_at" "$top_web_clients" "$tcpdump_mode"
        elif [ -n "$bulk_clients" ] && [ -n "$web_clients" ] && { [ "$bulk_clients" -gt 0 ] || [ "$web_clients" -gt 0 ]; }; then
            log_info "Starting Bulk/Web Clients Experiment..."
            launch_clients "$name" "$file_size" "$i" "$end_test_at" "$bulk_clients" "$web_clients" "$tcpdump_mode"
        else
            # shellcheck disable=SC2140
            log_fatal "run_performance_experiment()" "Number of clients wrongly specified in the configuration. Set "bulk_clients" and "web_clients" or "top_web_clients" in the experiment params."
        fi

        log_success "Performance Experiment Successful!\n"

        if [ "${CONFIG["copy_logs"]}" = true ]; then
            save_logs "$name" "$i" "$file_size" "$tor_params" "$client_params"
        fi

    done
}

save_logs() {
    tmp_dir="${CONFIG["absolute_path_dir"]}/tmp"
    logs_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}"
    copy_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["copy_target"]}$1-$2"
    log_info "Copying logs to ${copy_dir}"

    mkdir -p "${copy_dir}"
    # Copy cURL logs
    #cp -r "${tmp_dir}/curl/" "${copy_dir}/curl"

    # Copy Tor logs
    mkdir -p "${copy_dir}/tor"
    cp -r "${logs_dir}tor" "${copy_dir}"

    # Copy pcap logs
    zip -r "${copy_dir}/$1.zip" "${logs_dir}wireshark/" || log_fatal "Failed to zip pcap logs"

    rm -rf "${tmp_dir}/$1-$2" || log_fatal "Failed to clean temporary directory: $tmp_dir"

    echo '{
        "name": "'"$1"'",
        "file_size": "'"$3"'",
        "tor_params": '"$4"',
        "client_params": '"$5"'
    }' >"${copy_dir}/info.json"

    log_success "Logs copied to ${copy_dir} successfully!"
}
