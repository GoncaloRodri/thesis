#!/bin/bash

cd ~/Documents/thesis/

echo -e "\n🔷 🧹 Cleaning Docker Environment..."

docker compose down --remove-orphans
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)
docker network rm $(docker network ls -q)
docker volume rm $(docker volume ls -q)

echo -e "\n🔷 🕸️ Creating Docker Network..."

docker network create \
  --driver=bridge \
  --subnet=10.5.0.0/16 \
  net 


echo -e "\n🔷 🧅 Launching Tor Network via Docker Compose..."

COMPOSE_BAKE=true docker compose up --build -d

echo -e "\n🔷 📦 Installing TGen while Tor nodes bootstrap..."

docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)"
docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)"


##########################################
# Waiting for Bootstrap
##########################################

echo -e "\n🔷 ⏳ Waiting for Tor Network to be ready..."
sleep 120
echo -e "\n\033[1;36m🔶 ⏱️ 120 seconds elapsed!\033[0m"

while true; do
    read -p $'\n\033[1;36mDo you want to [W]ait, [E]xit or [P]roceed? \033[0m' exp
  
    case "$exp" in
        [Ww]* ) echo -e "\033[1;34m⏳ Waiting a bit longer...\033[0m"; sleep 45; echo -e "\n\033[1;36m🔶 ⏱️ 45 seconds elapsed!\033[0m" ; continue;;
        [PpYy]* ) echo -e "\033[1;32m✅ Proceeding...\033[0m"; break;;
        [Ee]* ) echo -e "\033[1;31m❌ Exiting.\033[0m"; exit 1;;
        [\n] ) echo "Entered enter";;
        * ) echo -e "⚠️ \033[0;33mPlease answer y or n.\033[0m";;
    esac
done

########################################
# Start TCPDUMP
########################################
echo

TGEN=true

read -p $'\033[1;33mDo you want to run tgen?\033[0m (y/n)' tgen
case "$tgen" in
    [Nn]* ) TGEN=false ;;
    * ) echo "Running TGen";;
esac


if [ "$TGEN" = true ]; then  
    docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/tor/logs/server.tgen.log";
    docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/tor/logs/client.tgen.log";
fi

#####################################
# Stop Docker Environment
#####################################
echo

STOP_DOCKER=true

read -p $'\033[1;33mDo you want to stop docker environment?\033[0m (y/n)' docker
case "$dockerr" in
    [Nn]* ) STOP_DOCKER=false ;;
    * ) echo "Stopping docker environment";;
esac


if [ "$STOP_DOCKER" = true ]; then
    docker compose down --remove-orphans
fi

######################################
# Wireshark
######################################

