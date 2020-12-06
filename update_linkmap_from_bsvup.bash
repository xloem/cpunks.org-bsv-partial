#!/usr/bin/env bash

# This code is duplicated inside mutate_path_to_txlinks.bash atm
# Ideally a linkmap like this would select the right matching transaction when there are more than one.
# The mutator could also be changed to show all the matching transactions at time of run, possibly.

for tx in .bsv/{tx,unbroadcasted}/*
do
    xxd -r -ps "$tx" | strings
done | sed -ne 's/.*19iG3WTYSsbyos3uJ733yK4zEioi1FesNU.\(.*\)@\([0-9a-fA-F]*\)/\1 \2/p' > linkmap.list
