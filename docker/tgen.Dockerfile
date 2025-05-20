FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    git cmake libglib2.0-dev libigraph-dev python3

WORKDIR /app/

COPY configuration/.config/ /conf
COPY configuration/tgen/ /app/
COPY scripts/entrypoint.sh /entrypoint.sh

RUN cd /app/ && ./install-tgen.sh
