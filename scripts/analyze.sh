#!/bin/bash

analyze() {
    echo -e "\n🔷 📦 Analyzing..."

    if [ "$#" -ne 1 ]; then
        VERSION="0"
    fi

    cd test || exit 1
    mkdir plots/"$SIZE-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.V$VERSION"
    python3 main.py --test "$SIZE-Dummy$DUMMY_CELL_GEN_RATIO-Jitter$JITTER_RATIO.V$VERSION" -f
    cd .. || exit 1

}
