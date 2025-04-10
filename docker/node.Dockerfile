FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    git cmake libglib2.0-dev libigraph-dev tcpdump 
# nano net-tools curl netcat-traditional 

WORKDIR /app/tor

COPY differential-privacy-tor /app/tor
COPY configuration/.config/ /conf
#COPY configuration/ /app/source
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]