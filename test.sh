#!/bin/bash

# shellcheck disable=SC1091

######################################################
### Variables
######################################################
LOOP=20
NUM_TEST=1
SCENARIO=""
COMPOSE_FILE=""
BOOTSTRAP_SLEEP=5
INTERVAL_BETWEEN_TESTS=30
SIZE="5mib"
TCPDUMP=false

######################################################
### Tor Configuration
######################################################
SCHEDULER="DPVanilla"
JITTER_MIN=1
JITTER_MAX=10
JITTER_RATIO=50
DUMMY_CELL_GEN_RATIO=50
####################################################
### Build
####################################################

set_configuration() {
    sed -E -i "s/(DummyCellGeneration )[0-9]+/\1$DUMMY_CELL_GEN_RATIO/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerJitter )[0-9]+/\1$JITTER_RATIO/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerRunIntervalMin )[0-9]+/\1$JITTER_MIN/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerRunIntervalMax )[0-9]+/\1$JITTER_MAX/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(Schedulers )[a-zA-Z0-9]+/\1$SCHEDULER/g" configuration/.config/tor.common.torrc
}

check_bootstrapped() {
    BSED=$(grep -l -R "Bootstrapped 100%" logs/* | wc -l)
    if [ "$BSED" -eq 6 ] || { [ "$BSED" -eq 5 ] && [ "$SCENARIO" = "s" ]; }; then
        echo -e "\033[1;32m✅ Tor Network is bootstrapped!\033[0m"
        return 1
    else
        echo -e "\033[1;31m❌ Tor Network is not bootstrapped yet! [$BSED/6]\033[0m"
        return 0
    fi
}

docker_clean() {
    docker compose -f simple.docker-compose.yml down --remove-orphans
    docker compose -f hs.docker-compose.yml down --remove-orphans
    docker stop "$(docker ps -aq)"
    docker rm "$(docker ps -aq)"
    docker rmi "$(docker images -q)"
    docker network rm "$(docker network ls -q)"
    docker volume rm "$(docker volume ls -q)"
}

docker_build() {
    docker build -t dptor_node -f docker/node.Dockerfile .
    docker network create \
        --driver=bridge \
        --subnet=10.5.0.0/16 \
        net

    COMPOSE_BAKE=true docker compose -f "$COMPOSE_FILE" up -d
}

install_tgen() {

    if [ "$SCENARIO" = "hidden_service" ] || [ "$SCENARIO" = "hs" ]; then
        docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
    fi
    docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)"
}

build() {
    set_configuration

    docker_clean

    docker_build

    install_tgen

    for i in $(seq 1 "$LOOP"); do
        sleep "$BOOTSTRAP_SLEEP"
        check_bootstrapped
        if [ $? -eq 1 ]; then
            break
        fi
        if [ "$i" -eq "$LOOP" ]; then
            echo -e "\033[1;31m❌ Tor Network is not bootstrapped! [$i/$LOOP]\033[0m"
            echo -e "\033[1;31m❌ Exiting...\033[0m"
            exit 1
        fi
    done

    echo -e "\033[1;32m✅ Tor Network is bootstrapped!\033[0m"
}

####################################################
### Run
####################################################
run_tcpdump() {
    if [ "$TCPDUMP" = true ]; then
        echo -e "\n🔷 📦 Running TCPDump..."
        docker exec -d thesis-client-1 sh -c "(tcpdump -i eth0 port 9001 -w /app/logs/wireshark/$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.client.pcap)"
        docker exec -d thesis-relay1-1 sh -c "(tcpdump -i eth0 port 9001 -w /app/logs/wireshark/$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.relay1.pcap)"
    fi
}

run_tests() {
    if [ "$SCENARIO" = "hs" ]; then
        echo -e "\n🔷 📦 Running TGen for Hidden Service"
        docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/logs/tgen/server.tgen.log" || exit 1
        docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/logs/tgen/client.tgen.log" || exit 1
    elif [ "$SCENARIO" = "s" ]; then
        echo -e "\n🔷 📦 Running TGen for Simple Scenario"
        docker exec thesis-client-1 sh -c "(tgen /app/proxy.tgenrc.graphml) | tee /app/logs/tgen/simple-client.tgen.log"
    else
        echo -e "\n 🔷 📦 Scenario not compatible!"
        echo -e "\033[1;31m❌ Exiting...\033[0m"
        exit 1
    fi
}

run() {
    run_tcpdump
    run_tests
}

#####################################################
### Analyze
#####################################################
analyze() {
    echo -e "\n🔷 📦 Analyzing..."

    if [ "$#" -ne 1 ]; then
        VERSION="0"
    else
        VERSION="$1"
    fi

    cd test || exit 1
    mkdir plots/"$SIZE-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.V$VERSION"
    python3 main.py --test "$SIZE-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.V$VERSION" -f
    cd .. || exit 1

}

#####################################################

print_env() {
    echo -e "\n🔷 📦 Environment Variables:"
    echo -e "  - LOOP: $LOOP"
    echo -e "  - NUM_TEST: $NUM_TEST"
    echo -e "  - SCENARIO: $SCENARIO"
    echo -e "  - COMPOSE_FILE: $COMPOSE_FILE"
    echo -e "  - BOOTSTRAP_SLEEP: $BOOTSTRAP_SLEEP"
    echo -e "  - INTERVAL_BETWEEN_TESTS: $INTERVAL_BETWEEN_TESTS"
    echo
    echo -e "\n🧅 Tor Configuration:"
    echo -e "  - Schedulers: $SCHEDULER"
    echo -e "  - DPSchedulerJitter: $JITTER_RATIO"
    echo -e "  - DPSchedulerRunIntervalMin: $JITTER_MIN"
    echo -e "  - DPSchedulerRunIntervalMax: $JITTER_MAX"
    echo -e "  - DummyCellGeneration: $DUMMY_CELL_GEN_RATIO"
    echo
}

print_help() {
    echo -e "\n🔷 📦 Usage: $0 [options]"
    echo -e "Options:"
    echo -e "  -s, --scenario <scenario>    Specify the scenario (hidden_service/hs or simple/s)"
    echo -e "  -f, --file <compose_file>    Specify the compose file"
    echo -e "  -n, --num-tests <num_tests>  Specify the number of tests to run"
    echo -e "  -h, --help                   Show this help message"

    echo -e "\n🔷 Tor Configuration"
    echo -e "  --dummy-cell-gen-ratio <ratio>  Set DummyCellGeneration ratio (0-100) [default: 50]}"
    echo -e "  --jitter-ratio <ratio>          Set DPSchedulerJitter ratio  (0-100) [default: 50]}"
    echo -e "  --jitter-min <min>              Set DPSchedulerRunIntervalMin [default: 1]}"
    echo -e "  --jitter-max <max>              Set DPSchedulerRunIntervalMax [default: 10]}"
    echo -e "  --scheduler <scheduler>         Set the scheduler type (DPVanilla)"

}

handle_args() {
    # Define short and long options
    local SHORT_OPTS="s:f:n:l:t:a:byh"
    local LONG_OPTS="scenario:,file:,num-tests:,loop:,dummy-cell-gen-ratio:,jitter-ratio:,jitter-min:,jitter-max:,scheduler:,test:,analyze:,build,yes,help,tcpdump"

    # Parse using getopt
    local PARSED_ARGS
    if ! PARSED_ARGS=$(getopt -o "$SHORT_OPTS" -l "$LONG_OPTS" -n "$0" -- "$@"); then
        exit 1
    fi

    eval set -- "$PARSED_ARGS"

    # Process options
    while true; do
        case "$1" in
        --dummy-cell-gen-ratio)
            DUMMY_CELL_GEN_RATIO="$2"
            if [[ "$DUMMY_CELL_GEN_RATIO" -lt 0 || "$DUMMY_CELL_GEN_RATIO" -gt 100 ]]; then
                echo "DummyCellGeneration ratio must be between 0 and 100."
                exit 1
            fi
            shift 2
            ;;
        --jitter-ratio)
            JITTER_RATIO="$2"
            if [[ "$JITTER_RATIO" -lt 0 || "$JITTER_RATIO" -gt 100 ]]; then
                echo "DPSchedulerJitter ratio must be between 0 and 100."
                exit 1
            fi
            shift 2
            ;;
        --jitter-min)
            JITTER_MIN="$2"
            if [[ "$JITTER_MIN" -lt 0 ]]; then
                echo "DPSchedulerRunIntervalMin must be greater than or equal to 0."
                exit 1
            fi
            shift 2
            ;;
        --jitter-max)
            JITTER_MAX="$2"
            if [[ "$JITTER_MAX" -lt 0 ]]; then
                echo "DPSchedulerRunIntervalMax must be greater than or equal to 0."
                exit 1
            fi
            shift 2
            ;;
        --scheduler)
            SCHEDULER="$2"
            if [[ "$SCHEDULER" != "DPVanilla" ]]; then
                echo "Scheduler type must be DPVanilla."
                exit 1
            fi
            shift 2
            ;;
        -s | --scenario)
            SCENARIO="$2"
            if [[ "$SCENARIO" = "hidden_service" || "$SCENARIO" = "hs" ]]; then
                SCENARIO="hs"
                COMPOSE_FILE="hs.docker-compose.yml"
            elif [[ "$SCENARIO" = "simple" || "$SCENARIO" = "s" ]]; then
                SCENARIO="s"
                COMPOSE_FILE="simple.docker-compose.yml"
            else
                echo "Invalid scenario. Use 'hidden_service' or 'simple'."
                exit 1
            fi
            shift 2
            ;;
        -f | --file)
            if [ -n "$COMPOSE_FILE" ]; then
                echo "WARNING: Multiple compose files specified. Using scenario file!"
                shift 2
                continue
            fi
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -n | --num-tests)
            NUM_TEST="$2"
            shift 2
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
        esac
    done
}

handle_args "$@"

print_env

build

for i in $(seq 1 "$NUM_TEST"); do
    run
    analyze "$i"
done
