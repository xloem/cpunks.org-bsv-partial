#!/usr/bin/env bash

folder=lists.cpunks.org/pipermail/cypherpunks/2020-September

# download from server
wget --no-parent --mirror https://"$folder".txt.gz https://"$folder/"


# calculate mailfile numbers and paths
mailhtmlfiles="$(ls "$folder"/??????.html | grep '/[0-9]*\.html$' | sort -n)"
firstmailnum="$(echo "$mailhtmlfiles" | head -n 1)"
firstmailnum="${firstmailnum##*/}"
firstmailnum="$(expr "${firstmailnum%.html}" + 0)"
mailhtmlcount="$(echo "$mailhtmlfiles" | wc -l)"

# download attachments
sed -ne 's/.*HREF="\([^"]*\/attachments\/[^"]*\)".*/\1/p' $mailhtmlfiles | xargs wget --mirror


# extract raw emails
zcat "$folder".txt.gz | csplit --elide-empty-files --digits 6 --prefix "$folder/" --suffix-format="extracted-%06d.txt" - '/^From .*[0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/' '{*}'
mailtxtcount="$(ls "$folder"/extracted-??????.txt | wc -l)"

# shift raw email numbers to match
for mailtxtfile in "$folder"/extracted-??????.txt
do
    num="${mailtxtfile##*/extracted-}"
    num="$(expr "${num%.txt}" + 0)" # expr removes leading 0s during addition
    mv "$mailtxtfile" "$folder"/"$(printf %06d $((num + firstmailnum)))".txt -v
done
