FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    tcpdump
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

# Copy your compiled tor binary
COPY /differential-privacy-tor /app/tor 
COPY dptor/.config/ /app/tor/conf/
COPY dptor/exit1/config/ /app/tor/
COPY dptor/exit1/crypto/ /app/tor/
COPY entrypoint.sh /entrypoint.sh

EXPOSE 9112

RUN ./configure && \
    make && \
    make install

RUN mkdir logs

ENTRYPOINT [ "/entrypoint.sh", "exit1" ]
