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
COPY dptor/authority/torrc /etc/tor/torrc
COPY dptor/conf/ /app/tor/conf/
COPY dptor/authority/ /app/tor/
COPY dptor/authority/ /root/.tor/
COPY dptor/hidden_service/ /root/.tor/hidden_service/
COPY entrypoint.sh /entrypoint.sh

EXPOSE 9112

RUN mkdir /var/lib/tor

RUN ./configure && \
    make && \
    make install

RUN mkdir logs
RUN mkdir logs/tcpdump

#CMD ["bash", "-c", "while true; do sleep 1000; done"]
ENTRYPOINT [ "/entrypoint.sh", "authority" ]