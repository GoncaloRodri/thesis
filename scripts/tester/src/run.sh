#!/bin/bash

# shellcheck disable=SC1091
source src/utils.sh
# shellcheck disable=SC1091
source src/build.sh
source src/clients.sh

DOCKER_COMPOSE_FILE="curl.docker-compose.yml"

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

        log_info "Cleaning up Docker containers and images..."
        docker_clean
        log_success "Docker cleanup Completed!\n"

        log_info "Setting up Torrc Configuration..."
        set_configuration "$tor_params"
        log_success "Torrc Configuration Completed!\n"

        log_info "Launching Virtual Tor Network..."
        launch_tor_network "${CONFIG["absolute_path_dir"]}/${DOCKER_COMPOSE_FILE}"
        log_success "Virtual Tor Network Launched!\n"

        log_info "Starting Performance Experiment..."

        if [ -n "$top_web_clients" ] && [ "$top_web_clients" -gt 0 ]; then
            launch_topweb_clients "$name" "$file_size" "$i" "$end_test_at" "$top_web_clients" "$tcpdump_mode"
        elif [ -n "$bulk_clients" ] && [ -n "$web_clients" ] && { [ "$bulk_clients" -gt 0 ] || [ "$web_clients" -gt 0 ]; }; then
            launch_clients "$name" "$file_size" "$i" "$end_test_at" "$bulk_clients" "$web_clients" "$tcpdump_mode"
        else
            # shellcheck disable=SC2140
            log_fatal "run_performance_experiment()" "Number of clients wrongly specified in the configuration. Set "bulk_clients" and "web_clients" or "top_web_clients" in the experiment params."
        fi

        log_success "Performance Experiment Successful!\n"

        if [ "${CONFIG["copy_logs"]}" = true ]; then
            save_logs "$name-$i"
        fi

    done
}

save_logs() {
    tmp_dir="${CONFIG["absolute_path_dir"]}/tmp"
    copy_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["copy_target"]}$1"
    log_info "Copying logs to ${copy_dir}"

    mkdir -p "${CONFIG["absolute_path_dir"]}/${CONFIG["copy_target"]}"
    # Copy cURL logs
    cp -r "${tmp_dir}/" "${copy_dir}"

    # Copy Tor logs
    cp -r "${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}tor" "${copy_dir}"

    # Copy pcap logs
    #cp -r "${tmp_dir}/pcap" "${copy_dir}/pcap"

    rm -rf "${tmp_dir:?}/*" || log_fatal "Failed to clean temporary directory: $tmp_dir"
    log_success "Logs copied to ${copy_dir} successfully!"
}
