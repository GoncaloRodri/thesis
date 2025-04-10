FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    tcpdump
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

COPY /differential-privacy-tor /app/tor 
COPY dptor/.config/ /app/tor/conf/
COPY dptor/relay2/config/ /app/tor/
COPY dptor/relay2/crypto/ /app/tor/
COPY entrypoint.sh /entrypoint.sh

EXPOSE 9112

RUN ./configure && \
    make && \
    make install

RUN mkdir logs

RUN mkdir logs/tcpdump

ENTRYPOINT [ "/entrypoint.sh", "relay2" ]
