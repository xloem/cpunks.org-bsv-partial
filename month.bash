#!/usr/bin/env bash
set -e # failure of any command fails the script immediately

date=1993-7

timestamp="$(date --date="$date"-15 +%s 2>/dev/null || date --date="$date"/15 +%s 2>/dev/null || date --date="${date% *} 15 ${date#* }" +%s 2>/dev/null || date --date="${date%/*}/15/${date#*/}" +%s 2>/dev/null || date --date="$date" +%s)"
year="$(date --date=@$timestamp +%Y)"
month="$(date --date=@$timestamp +%m)"

echo
echo "Pursuing archival of $year-$month"
echo

monthprev="$(date --date=@$((timestamp-60*60*24*30)) +%m)"
monthnext="$(date --date=@$((timestamp+60*60*24*30)) +%m)"
monthname="$(date --date=@$timestamp +%B)"
password=''

for list in cypherpunks cypherpunks-legacy
do # this is the only unindented block

folder=lists.cpunks.org/pipermail/$list/$year-$monthname
attachmentsfolder=lists.cpunks.org/pipermail/$list/attachments

# download from server
if ! wget --mirror https://"$folder".txt.gz
then
    continue
fi
wget --no-parent --mirror https://"$folder"/


# calculate mailfile numbers and paths
mailhtmlfiles="$(ls "$folder"/??????.html | grep '/[0-9]*\.html$' | sort -n)"
firstmailnum="$(echo "$mailhtmlfiles" | head -n 1)"
firstmailnum="${firstmailnum##*/}"
firstmailnum="$(expr "${firstmailnum%.html}" + 0)"
mailhtmlcount="$(echo "$mailhtmlfiles" | wc -l)"

# download attachments
sed -ne 's/.*HREF="\([^"]*\/attachments\/[0-9][0-9]*\/[^"]*\)".*/\1/p' $mailhtmlfiles | xargs wget --mirror

# extract raw emails
zcat "$folder".txt.gz | csplit --elide-empty-files --digits 6 --prefix "$folder/" --suffix-format="extracted-%06d.txt" - '/^From .*[0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/' '{*}'
mailtxtcount="$(ls "$folder"/extracted-??????.txt | wc -l)"

# shift raw email numbers to match
for mailtxtfile in "$folder"/extracted-??????.txt
do
    num="${mailtxtfile##*/extracted-}"
    num="$(expr "${num%.txt}" + 0 || true)" # expr removes leading 0s during addition
    mv "$mailtxtfile" "$folder"/"$(printf %06d $((num + firstmailnum)))".txt -v
done

# install bsvup
if ! [ -e node_modules/bsvup ]
then
    npm install git+https://github.com/xloem/bsvup\#b388d69da516f151f3979b734a3b9a9fe7a95af5
fi
BSVUP=node_modules/.bin/bsvup

echo
echo "Uploading $year-$month"
if [ "$password" = '' ]
then
    echo
    read -s -p 'A password, to decrypt this private key for payment: ' password
    echo
fi

# presently need bsvup git in order to exit with failure for insufficient balance, which will make this script terminate early in that case
"$BSVUP" --file "$folder" --subdirectory "$folder" --password "$password" --rate 500 --broadcast upload

# we'll also want to upload the attachments here.  They can be moved into a temporary folder to work around the present bugs.
rm -rf tmp/"$attachmentsfolder" 2>/dev/null
mkdir -p tmp/"$attachmentsfolder"
cp -va "$attachmentsfolder"/"$year""$month"* "$attachmentsfolder"/"$year""$monthprev"* "$attachmentsfolder"/"$year""$monthnext"* tmp/"$attachmentsfolder" || true
"$BSVUP" --file tmp/"$attachmentsfolder" --subdirectory "$attachmentsfolder" --password "$password" --rate 500 --broadcast upload

# this hack stores a file pairing paths with bsv transactions
./update_linkmap_from_bsvup.bash

# mutate all the message files to use transaction links to attachments
for mailhtmlfile in $mailhtmlfiles
do
    ./mutate_path_to_txlinks.bash "$mailhtmlfile"
done

# upload the mutated message files
"$BSVUP" --file "$folder" --subdirectory "$folder" --password "$password" --rate 500 --broadcast upload

# update mapfile
./update_linkmap_from_bsvup.bash

# mutate the index files to use transaction links to messages
for index in thread date subject author
do
    ./mutate_path_to_txlinks.bash "$folder"/"$index".html
done

# upload the mutated index files
"$BSVUP" --file "$folder" --subdirectory "$folder" --password "$password" --rate 500 --broadcast upload

done # the only unindented block, a while loop over lists
