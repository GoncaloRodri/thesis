FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 python3-stem pkg-config \
    automake git cmake libglib2.0-dev libigraph-dev tcpdump 
# nano net-tools curl netcat-traditional 

WORKDIR /app/tor

COPY differential-privacy-tor /app/tor

RUN ./autogen.sh && \ 
    ./configure --disable-manpage --disable-asciidoc \
    --disable-html-manual --disable-unittests && \
    make && \
    make install

COPY configuration/.config/ /conf
COPY configuration/tgen/ /app/
COPY entrypoint.sh /entrypoint.sh


ENTRYPOINT [ "/entrypoint.sh" ]