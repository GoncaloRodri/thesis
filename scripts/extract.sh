#!/bin/bash

services=$(docker ps --format '{{.Names}}')

rm -f /app/extract/data/*.txt

for service in $services; do
    docker exec "$service" sh -c "mkdir -p /app/extract/data && python3 /app/extract/extractor.py | tee -a /app/extract/data/'$service'.txt"

done
