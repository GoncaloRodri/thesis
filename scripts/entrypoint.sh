#!/bin/bash

NODE_NAME=$1

mkdir -p /app/logs/tor

cp /app/source/"$NODE_NAME"/config/torrc /app/tor/torrc

if [ "$NODE_NAME" != "client" ]; then
    cp -r /app/source/"$NODE_NAME"/crypto/* /app/tor/
fi

if [ "$NODE_NAME" = "hidden_service" ]; then
    mkdir -p /root/.tor/hidden_service
    cp -r /app/hidden_service/* /root/.tor/hidden_service/
fi

cd /app/tor || exit 1

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$1".tor.log
