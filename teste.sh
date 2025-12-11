#!/bin/bash

detect_distro() {
    for f in /etc/*release; do
        [ -f "$f" ] || continue
        . "$f"
        echo "$NAME"
        return 0
    done

    echo "toybox.sh - detect_distro: ${RED}NotFound${NC}: Could not detect distribution name."
    exit 127
}

detect_distro
