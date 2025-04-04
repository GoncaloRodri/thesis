FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

COPY /differential-privacy-tor /app/tor
COPY dptor/conf/ /app/tor/conf/
COPY dptor/relay2/torrc /etc/tor/torrc
COPY dptor/relay2/ /app/tor/
COPY dptor/relay2/ /root/.tor/

EXPOSE 9112

RUN ./configure && \
    make && \
    make install

RUN mkdir logs

#CMD ["bash", "-c", "while true; do sleep 1000; done"]
CMD ["sh", "-c", "(tor -f torrc) | tee logs/relay2.tor.log"]
