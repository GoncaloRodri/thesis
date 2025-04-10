FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 pkg-config \
    tcpdump

WORKDIR /app/tor

# Copy your compiled tor binary
COPY /differential-privacy-tor /app/tor 
COPY dptor/.config/ /app/tor/conf/
COPY dptor/authority/config/ /app/tor/
COPY dptor/authority/crypto/ /app/tor/

COPY entrypoint.sh /entrypoint.sh

#EXPOSE 9112

RUN mkdir /var/lib/tor

RUN ./configure && \
    make && \
    make install


#CMD ["bash", "-c", "while true; do sleep 1000; done"]
ENTRYPOINT [ "/entrypoint.sh", "authority" ]