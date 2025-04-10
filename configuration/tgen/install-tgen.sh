#!/bin/bash

cd /app/ || exit 1

git clone https://github.com/shadow/tgen.git

cd tgen || exit 1

mkdir build && cd build || exit 1

cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local

make install
