cd ~/Documents/thesis/
echo
echo "[+] Cleaning Docker Environment"
echo
docker compose down --remove-orphans
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)
docker network rm $(docker network ls -q)
docker volume rm $(docker volume ls -q)

echo
echo "[+] Creating Network "
echo

docker network create \
  --driver=bridge \
  --subnet=10.5.0.0/16 \
  net 


echo
echo "[+] Launching Tor Network w/ Docker Compose"
echo

COMPOSE_BAKE=true docker compose up --build --remove-orphans -d


echo
echo "[+] Installing tgen while tor nodes are bootstrapping!"
echo

docker exec -d thesis-hs-1 sh -c "(cd /app/ && ./install-tgen.sh)"
docker exec -d thesis-client-1 sh -c "(cd /app/ && ./install-tgen.sh)"

echo
echo "[+] Waiting for Tor Network to be ready..."
echo
sleep 200


echo "[+] When all network is bootstrapped and ready"
read -p "Press enter to continue"


docker exec -d thesis-hs-1 sh -c "(tgen /app/server.tgenrc.graphml) | tee /app/tor/logs/server.tgen.log"
sleep 5
docker exec thesis-client-1 sh -c "(tgen /app/client.tgenrc.graphml) | tee /app/tor/logs/client.tgen.log"


