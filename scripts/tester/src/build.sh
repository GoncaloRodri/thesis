#!/bin/bash

# shellcheck disable=SC1091
source src/utils.sh

BOOTSTRAP_SLEEP=1
MAX_TIME_TO_BOOTSTRAP=90
PERFORMANCE_BOOTSTRAP_COUNTER=5

launch_tor_network() {

    if [ "$BUILD" == true ]; then
        log_info "launch_tor_network()" "Building Docker images..."
        docker build --no-cache -f "${CONFIG["absolute_path_dir"]}/docker/node.Dockerfile" -t dptor_node "${CONFIG["absolute_path_dir"]}" || log_fatal "launch_tor_network()" "Failed to build Docker image for curl.docker-compose.yml"
    fi

    while true; do
        COMPOSE_BAKE=true docker compose -f "$1" up -d

        local start end elapsed

        start=$(date +%s)
        end=$(date +%s)
        elapsed=$((end - start))

        while [ $elapsed -lt $MAX_TIME_TO_BOOTSTRAP ]; do
            sleep "$BOOTSTRAP_SLEEP"
            a=$(check_bootstrapped)
            if [ "$a" -eq $PERFORMANCE_BOOTSTRAP_COUNTER ]; then
                break 2
            fi
            end=$(date +%s)
            elapsed=$((end - start))
            if [[ "$VERBOSE" == true ]]; then
                echo -ne "⚠️ \e[33mWarning: Tor Network is not bootstrapped yet! ($a of $PERFORMANCE_BOOTSTRAP_COUNTER) [$elapsed s]\e[0m"\\r
            fi
        done
        log_error "launch_tor_network()                                             " "Tor Network failed to bootstrap within $MAX_TIME_TO_BOOTSTRAP seconds. Retrying..."
        docker compose -f "$1" down --remove-orphans
        sleep 20
    done

    echo
}

docker_clean() {
    cd "${CONFIG["absolute_path_dir"]}" || log_fatal "docker_clean()" "Failed to change directory to ${CONFIG["absolute_path_dir"]}"
    docker compose down --remove-orphans
}

set_configuration() {
    local params config_path dummy jitter min_j max_j sched

    params="$1"
    config_path="${CONFIG["absolute_path_dir"]}/${CONFIG["configuration_dir"]}"

    dummy=$(echo "$params" | jq -r '.dummy')
    jitter=$(echo "$params" | jq -r '.jitter')
    min_j=$(echo "$params" | jq -r '.min_jitter')
    max_j=$(echo "$params" | jq -r '.max_jitter')
    sched=$(echo "$params" | jq -r '.scheduler')

    #sed -E -i "s/(DummyCellGeneration )[0-9]+/\1${dummy}/g" "${config_path}"/.config/tor.common.torrc
    #sed -E -i "s/(DPSchedulerJitter )[0-9]+/\1${jitter}/g" "${config_path}"/.config/tor.common.torrc
    #sed -E -i "s/(DPSchedulerRunIntervalMin )[0-9]+/\1${min_j}/g" "${config_path}"/.config/tor.common.torrc
    #sed -E -i "s/(DPSchedulerRunIntervalMax )[0-9]+/\1${max_j}/g" "${config_path}"/.config/tor.common.torrc
    #sed -E -i "s/(Schedulers )[a-zA-Z0-9]+/\1${sched}/g" "${config_path}"/.config/tor.common.torrc

    sed -i "s/^DummyCellGeneration .*/DummyCellGeneration ${dummy}/" "${config_path}"/.config/tor.common.torrc
    sed -i "s/^DPSchedulerJitter .*/DPSchedulerJitter ${jitter}/" "${config_path}"/.config/tor.common.torrc
    sed -i "s/^DPSchedulerRunIntervalMin .*/DPSchedulerRunIntervalMin ${min_j}/" "${config_path}"/.config/tor.common.torrc
    sed -i "s/^DPSchedulerRunIntervalMax .*/DPSchedulerRunIntervalMax ${max_j}/" "${config_path}"/.config/tor.common.torrc
    sed -i "s/^Schedulers .*/Schedulers ${sched}/" "${config_path}"/.config/tor.common.torrc
}
