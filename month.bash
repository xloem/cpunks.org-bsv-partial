#!/usr/bin/env bash

folder=lists.cpunks.org/pipermail/cypherpunks/2020-September

# download from server
wget --no-parent --mirror https://"$folder".txt.gz https://"$folder/"

# calculate first email number
firstnum="$(cd "$folder"; ls ??????.html | grep ^[0-9] | sort -n | head -n 1)"
firstnum="$(expr "${firstnum%.html}" + 0)"

# extract raw emails
zcat "$folder".txt.gz | csplit --elide-empty-files --digits 6 --prefix "$folder/" --suffix-format="%06d.txt" - '/^From .*[0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/' '{*}'

# shift raw email numbers to match
for file in "$folder"/??????.txt
do
    num="${file##*/}"
    num="$(expr "${num%.txt}" + 0)" # expr removes leading 0s during addition
    mv "$file" "$folder"/"$(printf %06d $((num + firstnum)))".txt -v
done
