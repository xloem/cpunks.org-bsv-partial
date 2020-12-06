#!/usr/bin/env bash
set -e # failure of any immediate command fails the script immediately

folder=lists.cpunks.org/pipermail/cypherpunks/2020-September
attachments=lists.cpunks.org/pipermail/cypherpunks/attachments

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

# install bsvup
if ! [ -e node_modules/bsvup ]
then
    npm install git+https://github.com/monkeylord/bsvup\#0c0cf2842414ffffd7a4a6222c2d04f38cf1a15e
fi
BSVUP=node_modules/.bin/bsvup

echo
read -s -p 'A password: ' password
echo

# not sure whether bsvup needs a patch to return an exit code for insufficient balance.
"$BSVUP" --file "$folder" --subdirectory "$folder" --password "$password" --rate 500 --broadcast upload

# we'll also want to upload the attachments here.  They can be moved into a temporary folder to work around the present bugs.

./update_linkmap_from_bsvup.bash

## mutate all the message files
#for mailhtmlfile in $mailhtmlfiles
#do
#    ./mutate_path_to_txlinks.bash "$mailhtmlfile"
#done
#
## upload the mutated message files
#"$BSVUP" --file "$folder" --subdirectory "$folder" --password "$password" --rate 500 --broadcast upload
