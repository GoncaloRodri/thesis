FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    git cmake libglib2.0-dev libigraph-dev nano net-tools curl \
    netcat-traditional tcpdump
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

COPY differential-privacy-tor /app/tor

COPY dptor/client/torrc /etc/tor/torrc
COPY dptor/client/ /root/.tor/
COPY dptor/client/ /app/tor/

COPY dptor/conf/ /app/tor/conf/

COPY dptor/tgen/ /app/

COPY entrypoint.sh /entrypoint.sh

RUN ./configure && \
    make && \
    make install

RUN mkdir logs
RUN mkdir logs/tcpdump


ENTRYPOINT [ "/entrypoint.sh", "client" ]
