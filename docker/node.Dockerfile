FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 python3-stem pkg-config \
    automake git cmake libglib2.0-dev libigraph-dev \ 
    tcpdump curl python3-dev python3.12-venv python3-pip 

WORKDIR /app

COPY differential-privacy-tor /app/tor

RUN cd /app/tor ./autogen.sh && \ 
    ./configure --disable-manpage --disable-asciidoc \
    --disable-html-manual --disable-unittests && \
    make && \
    make install

COPY configuration/.config/ /conf
COPY configuration/tgen/ /app/
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/ /app/


ENTRYPOINT [ "/entrypoint.sh" ]