#!/usr/bin/env bash
set -e # failure of any command fails the script immediately

#date=1993-7
date="$*"

timestamp="$(date --date="$date"-15 +%s 2>/dev/null || date --date="$date"/15 +%s 2>/dev/null || date --date="${date% *} 15 ${date#* }" +%s 2>/dev/null || date --date="${date%/*}/15/${date#*/}" +%s 2>/dev/null || date --date="$date" +%s)"
year="$(date --date=@$timestamp +%Y)"
month="$(date --date=@$timestamp +%m)"

echo
echo "Pursuing archival of $year-$month"
echo

monthprev="$(date --date=@$((timestamp-60*60*24*30)) +%m)"
monthnext="$(date --date=@$((timestamp+60*60*24*30)) +%m)"
monthname="$(date --date=@$timestamp +%B)"

for listandstartnum in "cypherpunks 015544" "cypherpunks-legacy 000362"
do # this is the only unindented block

list="${listandstartnum% *}"
startnum="${listandstartnum#* }"

folder=lists.cpunks.org/pipermail/$list/$year-$monthname
attachmentsfolder=lists.cpunks.org/pipermail/$list/attachments
mboxfile=lists.cpunks.org/pipermail/${list}.mbox/${list}.mbox

# download from server
if ! wget --mirror https://"$folder".txt.gz && ! wget --mirror https://"$folder".txt
then
    continue
fi
### commented out to speed up debugging
### wget --no-parent --mirror https://"$folder"/


# calculate mailfile numbers and paths
mailhtmlfiles="$(ls "$folder"/??????.html | grep '/[0-9]*\.html$' | sort -n)"
firstmailnum="$(echo "$mailhtmlfiles" | head -n 1)"
firstmailnum="${firstmailnum##*/}"
firstmailnum="$(expr "${firstmailnum%.html}" + 0)"
mailhtmlcount="$(echo "$mailhtmlfiles" | wc -l)"

# download attachments
### commented out to speed up debugging
### sed -ne 's/.*HREF="\([^"]*\/attachments\/[0-9][0-9]*\/[^"]*\)".*/\1/p' $mailhtmlfiles | xargs wget --mirror

# extract new raw emails
./update_mbox.bash "$mboxfile"

# extract text emails
{ zcat "$folder".txt.gz || cat "$folder".txt; } | csplit --elide-empty-files --digits 6 --prefix "$folder/" --suffix-format="extracted-%06d.txt" - '/^From .*[0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/' '{*}'
./mbox_extracted_rename.nodejs "$folder" 'extracted-[0-9]*.txt'

# match raw and text emails with the email numbers
mboxfolder="$(dirname "$mboxfile")"
for mailhtmlfile in $mailhtmlfiles
do
    mailemlfile="${mailhtmlfile%.html}.eml.txt"
    mailtxtfile="${mailhtmlfile%.html}.txt"
    # extract time and author from html
    maildate="$(sed -ne 's!.*<I>\([^<]* [0-9][0-9][0-9][0-9]\)</I>.*!\1!p' "$mailhtmlfile" | head -n 1)"
    maildate="$(date --date "$maildate" +%s)"
    mailfrom="$(sed -ne 's!.*TITLE=.*>\(.*\) at \(.*\)$!\1_\2!p' "$mailhtmlfile" | head -n 1)"
    mv -v "$folder"/"$maildate"_"$mailfrom".txt  "$mailtxtfile"
    srcfile="$mboxfolder"/"$maildate"_"$mailfrom".txt
    if [ -e "$mailemlfile" ] && ! [ -e "$srcfile" ]
    then
        continue
    fi
    mv -v "$mboxfolder"/"$maildate"_"$mailfrom".txt "$mailemlfile"
done

# # renumber text emails to match html emails
# for mailhtmlfile in $mailhtmlfiles
# do
#     mailtxtfile="${mailhtmlfile%.html}.txt"
#     num="${mailhtmlfile##*/}"
#     num="$(expr "${num%.html}" + 0 || true)" # expr removes leading 0s during addition
#     extracted="$(ls "$folder"/extracted-??????.txt | head -n 1)"
#     mv -v "$extracted" "$mailtxtfile"
# done
# for extracted in "$folder"/extracted-??????.txt
# do
#     num=$((num+1))
#     mv -v "$extracted" "$folder"/"$(printf %06d $((num)))".txt
# done

# install bsvup
if ! [ -e node_modules/bsvup ]
then
    npm install git+https://github.com/xloem/bsvup\#643f24266ece0d75eb52a34f37d47d93253f9ef0
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
rm -rf tmp/"$attachmentsfolder" 2>/dev/null || true
mkdir -p tmp/"$attachmentsfolder"
cp -va "$attachmentsfolder"/"$year""$month"* "$attachmentsfolder"/"$year""$monthprev"* "$attachmentsfolder"/"$year""$monthnext"* tmp/"$attachmentsfolder" || true
"$BSVUP" --file tmp/"$attachmentsfolder" --subdirectory "$attachmentsfolder" --password "$password" --rate 500 --broadcast upload

# hacks to store a file pairing paths with bsv transactions
rm -rf .bsv/tx/. 2>/dev/null || true # wipe stale links
./regenerate_tx_cache_from_txs_files.nodejs # produce new links
./update_linkmap_from_bsvup.bash # output

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

# update mapfile
./update_linkmap_from_bsvup.bash
