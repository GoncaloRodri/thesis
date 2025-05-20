#!/bin/bash

set_configuration() {
    sed -E -i "s/(DummyCellGeneration )[0-9]+/\1$DUMMY_CELL_GEN_RATIO/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerJitter )[0-9]+/\1$JITTER_RATIO/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerRunIntervalMin )[0-9]+/\1$JITTER_MIN/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(DPSchedulerRunIntervalMax )[0-9]+/\1$JITTER_MAX/g" configuration/.config/tor.common.torrc
    sed -E -i "s/(Schedulers )[a-zA-Z0-9]+/\1$SCHEDULER/g" configuration/.config/tor.common.torrc
}

check_bootstrapped() {
    BSED=$(grep -l -R "Bootstrapped 100%" logs/* | wc -l)
    echo "$SCENARIO"
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

#########################################################################################
############################              MAIN              #############################
#########################################################################################

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
