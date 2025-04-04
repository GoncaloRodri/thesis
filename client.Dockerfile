FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    git cmake libglib2.0-dev libigraph-dev nano net-tools curl netcat-traditional
    #&& rm -rf /var/lib/apt/lists/*

WORKDIR /app/tor

COPY /differential-privacy-tor /app/tor
COPY dptor/conf/ /app/tor/conf/
COPY dptor/client/torrc /etc/tor/torrc
COPY dptor/client/ /app/tor/
COPY dptor/client/ /root/.tor/

COPY /dptor/tgen/ /app/

RUN ./configure && \
    make && \
    make install

RUN mkdir logs

# RUN cd /app/ && git clone https://github.com/shadow/tgen.git && cd tgen && \
#     mkdir build && cd build && \
#     cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
#     make install

CMD ["sh", "-c", "(tor -f torrc) | tee logs/client.tor.log"]
