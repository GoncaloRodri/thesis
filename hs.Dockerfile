FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    git cmake libglib2.0-dev libigraph-dev
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

COPY /differential-privacy-tor /app/tor
COPY dptor/conf/ /app/tor/conf/
COPY dptor/hidden_service/torrc /etc/tor/torrc
COPY dptor/hidden_service/ /app/tor/
COPY dptor/hidden_service/ /root/.tor/

COPY /dptor/tgen/ /app/

RUN ./configure && \
    make && \
    make install

RUN mkdir logs

#CMD ["bash", "-c", "while true; do sleep 1000; done"]
CMD ["sh", "-c", "(tor -f torrc) | tee logs/hs.tor.log"]    