#!/bin/bash

# shellcheck disable=SC1091
source src/utils.sh
source src/build.sh
source src/clients.sh

DOCKER_COMPOSE_FILE="docker-compose.yml"

run_experiment() {
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

    echo "Running performance experiment: $name"
    echo "tcpdump_mode: $tcpdump_mode"
    echo "end_test_at: $end_test_at"
    echo "file_size: $file_size"
    echo "client_params: $client_params"
    echo "tor_params: $tor_params"

    for ((ii = 0; ii < $((repeat)); ii++)); do

        # Run the performance experiment
        log_info "Launching '$name-$ii'"
        mkdir -p "${CONFIG["absolute_path_dir"]}/backup/$name-$ii"

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
            launch_topweb_clients "$name" "$file_size" "$ii" "$end_test_at" "$top_web_clients" "$tcpdump_mode"
        elif [ -n "$bulk_clients" ] && [ -n "$web_clients" ] && { [ "$bulk_clients" -gt 0 ] || [ "$web_clients" -gt 0 ]; }; then
            log_info "Starting Bulk/Web Clients Experiment..."
            launch_clients "$name" "$file_size" "$ii" "$end_test_at" "$bulk_clients" "$web_clients" "$tcpdump_mode"
        else
            # shellcheck disable=SC2140
            log_fatal "run_performance_experiment()" "Number of clients wrongly specified in the configuration. Set "bulk_clients" and "web_clients" or "top_web_clients" in the experiment params."
        fi

        log_success "Performance Experiment Successful!\n"

        if [ "${CONFIG["copy_logs"]}" = true ]; then
            save_logs "$name" "$ii" "$file_size" "$tor_params" "$client_params" "$tcpdump_mode"
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
    if [ "$6" ]; then
        zip -r "${copy_dir}/$1.zip" "${logs_dir}wireshark/" || log_fatal "Failed to zip pcap logs"
        rm -rf "${tmp_dir}/$1-$2" || log_fatal "Failed to clean temporary directory: $tmp_dir"
    fi

    echo '{
        "name": "'"$1"'",
        "file_size": "'"$3"'",
        "tor_params": '"$4"',
        "client_params": '"$5"'
    }' >"${copy_dir}/info.json"

    log_success "Logs copied to ${copy_dir} successfully!"
}

run_combinations() {

    END_TEST_AT=$(echo "$COMBINATIONS" | jq '.end_test_at')
    TCP_DUMP_MODE=$(echo "$COMBINATIONS" | jq '.tcpdump')

    FILESIZE_LIST=$(echo "$COMBINATIONS" | jq '.filesize')
    NUM_FILESIZE=$(echo "$FILESIZE_LIST" | jq 'length')

    CLIENTS_LIST=$(echo "$COMBINATIONS" | jq '.clients')
    NUM_CLIENTS=$(echo "$CLIENTS_LIST" | jq 'length')

    DUMMY_LIST=$(echo "$COMBINATIONS" | jq '.tor.dummy')
    NUM_DUMMY=$(echo "$DUMMY_LIST" | jq 'length')

    MAX_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.max_jitter')
    NUM_MAX_JITTER=$(echo "$MAX_JITTER_LIST" | jq 'length')

    MIN_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.min_jitter')
    NUM_MIN_JITTER=$(echo "$MIN_JITTER_LIST" | jq 'length')

    TARGET_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.target_jitter')
    NUM_TARGET_JITTER=$(echo "$TARGET_JITTER_LIST" | jq 'length')

    DP_DIST_LIST=$(echo "$COMBINATIONS" | jq '.tor.dp_distribution')
    NUM_DP_DIST=$(echo "$DP_DIST_LIST" | jq 'length')

    DP_EPSILON_LIST=$(echo "$COMBINATIONS" | jq '.tor.dp_epsilon')
    NUM_DP_EPSILON=$(echo "$DP_EPSILON_LIST" | jq 'length')

    SCHEDULER_LIST=$(echo "$COMBINATIONS" | jq '.tor.scheduler')
    NUM_SCHEDULER=$(echo "$SCHEDULER_LIST" | jq 'length')

    for ((i = 0; i < NUM_CLIENTS; i++)); do
        for ((j = 0; j < NUM_DUMMY; j++)); do
            for ((k = 0; k < NUM_MAX_JITTER; k++)); do
                for ((ll = 0; ll < NUM_MIN_JITTER; ll++)); do
                    for ((m = 0; m < NUM_TARGET_JITTER; m++)); do
                        for ((n = 0; n < NUM_DP_DIST; n++)); do
                            for ((o = 0; o < NUM_DP_EPSILON; o++)); do
                                for ((p = 0; p < NUM_SCHEDULER; p++)); do
                                    for ((q = 0; q < NUM_FILESIZE; q++)); do
                                        tor_params=$(jq -n \
                                            --arg dummy "$(echo "$DUMMY_LIST" | jq -r ".[$j]")" \
                                            --arg max_jitter "$(echo "$MAX_JITTER_LIST" | jq -r ".[$k]")" \
                                            --arg min_jitter "$(echo "$MIN_JITTER_LIST" | jq -r ".[$ll]")" \
                                            --arg target_jitter "$(echo "$TARGET_JITTER_LIST" | jq -r ".[$m]")" \
                                            --arg dp_distribution "$(echo "$DP_DIST_LIST" | jq -r ".[$n]")" \
                                            --arg dp_epsilon "$(echo "$DP_EPSILON_LIST" | jq -r ".[$o]")" \
                                            --arg scheduler "$(echo "$SCHEDULER_LIST" | jq -r ".[$p]")" \
                                            '{dummy: $dummy, max_jitter: $max_jitter, min_jitter: $min_jitter, target_jitter: $target_jitter, dp_distribution: $dp_distribution, dp_epsilon: $dp_epsilon, scheduler: $scheduler}')

                                        client_params=$(jq -n \
                                            --arg bulk_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][0]")" \
                                            --arg web_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][1]")" \
                                            --arg top_web_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][2]")" \
                                            '{bulk_clients: ($bulk_clients | tonumber), web_clients: ($web_clients | tonumber), top_web_clients: ($top_web_clients | tonumber)}')
                                        file_size=$(echo "$FILESIZE_LIST" | jq -r ".[$q]")

                                        #SCHED - DIST - EPSILON - DUMMY - CLIENT_RATIO - FILESIZE
                                        name="$(echo "$SCHEDULER_LIST" | jq -r ".[$p]")-$(echo "$DP_DIST_LIST" | jq -r ".[$n]")-$(echo "$DP_EPSILON_LIST" | jq -r ".[$o]")-$(echo "$DUMMY_LIST" | jq -r ".[$j]")dum-${i}of$NUM_CLIENTS-$file_size"

                                        run_experiment "$name" "$TCP_DUMP_MODE" "$file_size" "$END_TEST_AT" "$client_params" "$tor_params"
                                    done
                                done
                            done
                        done
                    done
                done
            done
        done
    done

    log_success "All combinations executed successfully!"
}
