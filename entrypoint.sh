#!/bin/bash

mkdir /app/tor/logs
mkdir /app/tcpdump

#tcpdump -i eth0 port 9000 -w /app/tcpdump/$1.9000.pcap &
#tcpdump -i eth0 port 9051 -w /app/tcpdump/$1.9051.pcap &
tcpdump -i eth0 port 9111 -w /app/tcpdump/$1.9111.pcap &
#tcpdump -i eth0 port 9112 -w /app/tcpdump/$1.9112.pcap &
tcpdump -i eth0 -w /app/tcpdump/$1.all.pcap &


(tor -f torrc) | tee /app/tor/logs/$1.tor.log
