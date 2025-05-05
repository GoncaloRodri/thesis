#!/bin/bash

handle_args() {
    while getopts "hs:fta:" opt; do
        case $opt in
        h)
            show_help
            exit 0
            ;;
        s)
            SCENARIO=$OPTARG
            if [[ ! "$SCENARIO" =~ ^(simple|hidden_service|hs)$ ]]; then
                echo -e "\033[1;31mInvalid scenario: $SCENARIO\033[0m" >&2
                exit 1
            fi
            ;;
        t)
            TEST=true
            TEST_NAME=$OPTARG
            ;;
        f)
            TEST=true
            TEST_FILTERING=true
            TEST_NAME=$OPTARG
            ;;
        a)
            AUTO=true
            ;;
        \?)
            echo -e "\033[1;31mInvalid option: -$OPTARG\033[0m" >&2
            exit 1
            ;;
        :)
            echo -e "\033[1;31mOption -$OPTARG requires an argument.\033[0m" >&2
            exit 1
            ;;
        esac
    done
}

show_help() {
    echo -e "\033[1;34mUsage: build.sh -s [scenario] [options]\033[0m"
    echo -e "\033[1;34mOptions:\033[0m"
    echo -e "  \033[1;34m-h\033[0m                      Show this help message and exit"
    echo -e "  \033[1;34m-ps\033[0m                     Show the possible scenarios"
    echo -e "  \033[1;34m-f\033[0m                      Run tests after the scenario with filtering (default: false)"
    echo -e "  \033[1;34m-a\033[0m                      Run in auto mode (default: false)"
    echo -e "  \033[1;34m-s [scenario]\033[0m           Specify the scenario to run"
    echo -e "  \033[1;34m-t [test]\033[0m               Run tests after the scenario (default: false)"
    echo
    echo -e "\033[1;34mPossible scenarios:\033[0m"
    echo -e "  -> \033[1;34msimple [default]\033[0m        1 client, 3 tor relays & 1 tgen server"
    echo -e "  -> \033[1;34mhidden-service\033[0m or \033[1;34mhs\033[0m    1 client, 3 tor relays & 1 hidden service"
}

check_bootstrapped() {
    BSED=$(grep -l -R "Bootstrapped 100%" logs/* | wc -l)
    if [ "$BSED" -eq 6 ]; then
        echo -e "\033[1;32m✅ Tor Network is bootstrapped!\033[0m"
        return 1
    else
        echo -e "\033[1;31m❌ Tor Network is not bootstrapped yet! [$BSED/6]\033[0m"
        return 0
    fi
}

time_elapsed() {
    SECONDS=$((SECONDS - START_T))
    echo -e "\033[1;36m🔶 ⏱️ $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed!\033[0m"
}

kill_docker() {
    echo -e "\n🔷 🧹 Cleaning Docker Environment..."

    docker compose -f simple.docker-compose.yml down --remove-orphans
    docker compose -f hs.docker-compose.yml down --remove-orphans
    docker stop "$(docker ps -aq)"
    docker rm "$(docker ps -aq)"
    docker rmi "$(docker images -q)"
    docker network rm "$(docker network ls -q)"
    docker volume rm "$(docker volume ls -q)"
}

set_network() {
    echo -e "\n🔷 🕸️ Creating Docker Network..."

    docker network create \
        --driver=bridge \
        --subnet=10.5.0.0/16 \
        net
}

launch_compose() {
    echo -e "\n🔷 🧅 Launching Tor Network via Docker Compose..."

    docker build -t dptor_node -f docker/node.Dockerfile .

    COMPOSE_FILE="simple.docker-compose.yml"
    if [ "$SCENARIO" = "hidden_service" ] || [ "$SCENARIO" = "hs" ]; then
        echo -e "\n🔷 📦 Launching Hidden Service Scenario..."
        COMPOSE_FILE="hs.docker-compose.yml"
    else
        echo -e "\n🔷 📦 Launching Simple Scenario..."
    fi

    COMPOSE_BAKE=true docker compose -f $COMPOSE_FILE up -d
}

install_tgen() {
    echo -e "\n🔷 📦 Installing TGen while Tor nodes bootstrap..."
    if [ "$SCENARIO" = "hidden_service" ] || [ "$SCENARIO" = "hs" ]; then
        echo -e "\n🔷 📦 Installing TGen for Hidden Service Scenario..."
        docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
        docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
    else
        echo -e "\n🔷 📦 Installing TGen for Simple Scenario..."
        docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)"
    fi
}

run_tgen() {
    echo -e "\n🔷 📦 Running TGen..."

    if [ "$SCENARIO" = "hidden_service" ] || [ "$SCENARIO" = "hs" ]; then
        echo -e "\n🔷 📦 Running TGen for Hidden Service"
        docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/logs/tgen/server.tgen.log" || exit 1
        docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/logs/tgen/client.tgen.log" || exit 1
    else
        echo -e "\n🔷 📦 Running TGen for Simple Scenario"
        docker exec -d thesis-client-1 sh -c "(tgen /app/proxy.tgenrc.graphml) | tee /app/logs/tgen/simple-client.tgen.log"
    fi
}

cd ~/Documents/thesis/ || exit 1

SECONDS=0
START_T=$SECONDS
TEST=false
AUTO=false
TEST_NAME=""

handle_args "$@"

kill_docker

set_network

launch_compose

install_tgen

##########################################
# Waiting for Bootstrap
##########################################

echo -e "\n🔷 ⏳ Waiting for Tor Network to be ready..."
sleep 30
echo -e "\n\033[1;36m🔶 ⏱️ Waited 30 seconds!\033[0m"

while true; do
    if [ "$AUTO" = true ]; then
        R=check_bootstrapped
        if [ "$R" -eq 1 ]; then
            echo -e "\033[1;32m✅ Tor Network is bootstrapped!\033[0m"
            break
        else
            echo -e "\033[1;31m❌ Tor Network is not bootstrapped yet!\033[0m"
            sleep 10
            continue
        fi
    else
        check_bootstrapped
        time_elapsed
        read -r -p $'\n\033[1;36mDo you want to [W]ait, [E]xit or [P]roceed? \033[0m' exp

        case "$exp" in
        [Ww]*)
            echo -e "\033[1;34m⏳ Waiting a bit longer...\033[0m"
            sleep 30
            echo -e "\n\033[1;36m🔶 ⏱️ 30 seconds elapsed!\033[0m"
            continue
            ;;
        [PpYy]*)
            echo -e "\033[1;32m✅ Proceeding...\033[0m"
            break
            ;;
        [Ee]*)
            echo -e "\033[1;31m❌ Exiting.\033[0m"
            exit 1
            ;;
        ['\n']) echo "Entered enter" ;;
        *) echo -e "⚠️ \033[0;33mPlease answer y or n.\033[0m" ;;
        esac
    fi
done

run_tgen

echo -e "\n🔷  🧹 Stopping Docker"
docker compose -f $COMPOSE_FILE stop

if [ "$TEST" = true ]; then
    cd test/ || exit 1
    echo -e "\n🔷  📦 Running Tests"
    if [ "$TEST_FILTERING" = true ]; then
        python3 main.py -f --test "$TEST_NAME"
    else
        python3 main.py --test "$TEST_NAME"
    fi
fi
