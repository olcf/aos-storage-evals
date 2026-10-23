#!/bin/bash

if [ $# -ne 1 ]; then
    echo "USAGE ERROR: $0 <local-directory>"
    exit 1
fi

ldir=$1
fusermount3 -u $ldir