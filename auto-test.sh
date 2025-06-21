#!/bin/bash

######################################################
### Variables
######################################################
LOOP=5
NUM_TEST=1
SCENARIO=""
COMPOSE_FILE=""
BOOTSTRAP_SLEEP=20
INTERVAL_BETWEEN_TESTS=30
BUILD_DOCKER=false
SKIP_VERIFICATION=false
TEST=""
TCPDUMP=false

######################################################
### Tor Configuration
######################################################
SCHEDULER="DPVanilla"
JITTER_MIN=1
JITTER_MAX=10
JITTER_RATIO=50
DUMMY_CELL_GEN_RATIO=50

######################################################
### Functions
######################################################

print_help() {
    echo -e "\n🔷 📦 Usage: $0 [options]"
    echo -e "Options:"
    echo -e "  -s, --scenario <scenario>    Specify the scenario (hidden_service/hs or simple/s)"
    echo -e "  -f, --file <compose_file>    Specify the compose file"
    echo -e "  -n, --num-tests <num_tests>  Specify the number of tests to run"
    echo -e "  -l, --loop <loop>            Number of checks for Tor Network bootstrap status"
    echo -e "  -b, --build                  Build Docker images"
    echo -e "  -y, --yes                    Skip verification prompt"
    echo -e "  --tcpdump                    Enable TCPDump"
    echo -e "  -h, --help                   Show this help message"

    echo -e "\n🔷 Tor Configuration"
    echo -e "  --dummy-cell-gen-ratio <ratio>  Set DummyCellGeneration ratio (0-100) [default: 50]}"
    echo -e "  --jitter-ratio <ratio>          Set DPSchedulerJitter ratio  (0-100) [default: 50]}"
    echo -e "  --jitter-min <min>              Set DPSchedulerRunIntervalMin [default: 1]}"
    echo -e "  --jitter-max <max>              Set DPSchedulerRunIntervalMax [default: 10]}"
    echo -e "  --scheduler <scheduler>         Set the scheduler type (DPVanilla)"

}

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
    echo -e "  - DummyCellEpsilon: $DUMMY_CELL_GEN_RATIO"
    echo
}

set_configuration() {
    sed -E -i "s/(DummyCellEpsilon )[0-9]+/\1$DUMMY_CELL_GEN_RATIO/g" configuration/.config/tor.common.torrc
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

install_tgen() {
    if [ "$SCENARIO" = "hidden_service" ] || [ "$SCENARIO" = "hs" ]; then
        echo -e "\n🔷 📦 Installing TGen for Hidden Service Scenario..."
        docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
        docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
    else
        echo -e "\n🔷 📦 Installing TGen for Simple Scenario..."
        docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)"
    fi
}

run_tcpdump() {
    if [ "$TCPDUMP" = true ]; then
        echo -e "\n🔷 📦 Running TCPDump..."
        docker exec -d thesis-client-1 sh -c "(tcpdump -i eth0 port 9001 -w /app/logs/wireshark/$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.client.pcap)"
        docker exec -d thesis-relay1-1 sh -c "(tcpdump -i eth0 port 9001 -w /app/logs/wireshark/$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.relay1.pcap)"
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
    if [ "$BUILD_DOCKER" = true ]; then
        docker build -t dptor_node -f docker/node.Dockerfile .
    fi

    docker network create \
        --driver=bridge \
        --subnet=10.5.0.0/16 \
        net

    COMPOSE_BAKE=true docker compose -f "$COMPOSE_FILE" up -d
}

bootstrap_tor() {
    for i in $(seq 1 "$LOOP"); do
        sleep $BOOTSTRAP_SLEEP
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
}

analyze() {
    cd test || exit 1
    mkdir plots/"$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO"
    python3 main.py --test "$TEST-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO" -f
    cd .. || exit 1
}

######################################################
### Auxiliary Functions
######################################################
run_tgen_client() {
    local log_name="client_$1.tgen.log"
    local client_log_path="/app/logs/tgen/$log_name"
    docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee $client_log_path" || exit 1
}

######################################################
### Main Script
######################################################
handle_args "$@"

if [ -z "$COMPOSE_FILE" ]; then
    echo -e "\033[1;31mSelect 1 of the following Compose files:\033[0m"
    echo -e "\033[1;36m  [1] simple.docker-compose.yml\033[0m"
    echo -e "\033[1;36m  [2] hs.docker-compose.yml\033[0m"
    echo -e
    read -p "You can also use -f <compose_file> to specify a custom file.\n" -n 1 -r

    if [[ $REPLY =~ ^[1]$ ]]; then
        COMPOSE_FILE="simple.docker-compose.yml"
    elif [[ $REPLY =~ ^[2]$ ]]; then
        COMPOSE_FILE="hs.docker-compose.yml"
    else
        echo -e "\033[1;31m❌ Invalid selection! Exiting...\033[0m"
        exit 1
    fi
fi

print_env

if [ $SKIP_VERIFICATION = false ]; then
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\033[1;31m❌ Exiting...\033[0m"
        exit 1
    fi
fi

set_configuration

docker_clean

docker_build

install_tgen

bootstrap_tor

run_tcpdump
run_tests

echo -e "\n🔷 📦 Cleaning up..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans

if [ "$TEST" != "" ]; then
    analyze
fi

echo -e "\n🔷 📦 Done!"
