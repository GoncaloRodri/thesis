#!/bin/bash

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
