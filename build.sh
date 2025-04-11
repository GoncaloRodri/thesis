#!/bin/bash

check_bootstrapped() {
    BSED=$(grep -l -R "Bootstrapped 100%" logs/* | wc -l)
    if [ "$BSED" -eq 6 ]; then
        echo -e "\033[1;32m✅ Tor Network is bootstrapped!\033[0m"
    else
        echo -e "\033[1;31m❌ Tor Network is not bootstrapped yet! [$BSED/6]\033[0m"
    fi
}

time_elapsed() {
    SECONDS=$((SECONDS - START_T))
    echo -e "\033[1;36m🔶 ⏱️ $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed!\033[0m"
}

kill_docker() {
    echo -e "\n🔷 🧹 Cleaning Docker Environment..."

    docker compose down --remove-orphans
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

    COMPOSE_BAKE=true docker compose up -d
}

install_tgen() {
    echo -e "\n🔷 📦 Installing TGen while Tor nodes bootstrap..."

    docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
    docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)" || exit 1
}

run_tgen() {
    echo -e "\n🔷 📦 Running TGen..."

    docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/logs/tgen/server.tgen.log" || exit 1
    docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/logs/tgen/client.tgen.log" || exit 1
}

cd ~/Documents/thesis/ || exit 1

SECONDS=0
START_T=$SECONDS

kill_docker

set_network

launch_compose

install_tgen

##########################################
# Waiting for Bootstrap
##########################################

echo -e "\n🔷 ⏳ Waiting for Tor Network to be ready..."
sleep 20
echo -e "\n\033[1;36m🔶 ⏱️ Waited 20 seconds!\033[0m"

while true; do
    check_bootstrapped
    time_elapsed
    read -r -p $'\n\033[1;36mDo you want to [W]ait, [E]xit or [P]roceed? \033[0m' exp

    case "$exp" in
    [Ww]*)
        echo -e "\033[1;34m⏳ Waiting a bit longer...\033[0m"
        sleep 30
        echo -e "\n\033[1;36m🔶 ⏱️ 45 seconds elapsed!\033[0m"
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
done

run_tgen

########################################
# Start TCPDUMP
########################################
# echo

# TGEN=true

# read -r -p $'\033[1;33mDo you want to run tgen?\033[0m (y/n) ' tgen
# case "$tgen" in
# [Nn]*) TGEN=false ;;
# *) echo "Running TGen" ;;
# esac

# if [ "$TGEN" = true ]; then
#     docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/tor/logs/server.tgen.log"
#     docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/tor/logs/client.tgen.log"
# fi
