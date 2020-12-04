#!/usr/bin/env bash

dir=lists.cpunks.org/pipermail/cypherpunks/2020-September

bsvup --file "$dir" --subdirectory "$dir" --rate 500 upload

