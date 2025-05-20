#!/bin/bash

apt install python3.12-venv
cd ~/ || exit 1
python3 -m venv venv
source venv/bin/activate
which python3

git clone https://gitlab.torproject.org/tpo/network-health/metrics/onionperf.git
pip3 install --no-cache -r onionperf/requirements.txt

cd onionperf/ || exit 1
pip install -i .
