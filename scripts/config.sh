#!/bin/bash
# shellcheck disable=SC2034

######################################################
### Variables
######################################################
LOOP=5
NUM_TEST=1
SCENARIO=""
COMPOSE_FILE="simple.docker-compose.yml"
BOOTSTRAP_SLEEP=20
INTERVAL_BETWEEN_TESTS=30
BUILD_DOCKER=false
SKIP_VERIFICATION=false
SIZE="20mib"
TCPDUMP=false

######################################################
### Tor Configuration
######################################################
SCHEDULER="DPVanilla"
JITTER_MIN=1
JITTER_MAX=10
JITTER_RATIO=50
DUMMY_CELL_GEN_RATIO=50
