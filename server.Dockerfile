FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    git cmake libglib2.0-dev libigraph-dev
    #&& rm -rf /var/lib/apt/lists/*


WORKDIR /app/

COPY /dptor/tgen/ /app/

RUN git clone https://github.com/shadow/tgen.git && cd tgen && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make install

RUN mkdir logs

EXPOSE 8080

#CMD ["bash", "-c", "while true; do sleep 1000; done"]
CMD ["sh", "-c", "(tgen server.tgenrc.graphml) | tee logs/fileserver.tgen.log"]

