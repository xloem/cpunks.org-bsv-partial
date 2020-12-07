#!/usr/bin/env bash

# this removes txlink urls from the local cache, so new ones will be used when generated.

for tx in .bsv/{tx,unbroadcasted}/*
do
    xxd -r -ps "$tx" | strings | while read line
    do
        echo "$line" "$tx"
    done
done | sed -ne 's/.*19iG3WTYSsbyos3uJ733yK4zEioi1FesNU.\(.*\)@\([0-9a-fA-F]*\) \([0-9a-zA-Z]*\)/\1 \2 \3/p' | grep txlink | while read path tx file
do
    rm -v .bsv/tx/"$tx" "$file"
done
