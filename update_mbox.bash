#!/usr/bin/env bash
set -e

mboxfile="$1"
mboxfolder="$(dirname "$mboxfile")"

mkdir -p "$mboxfolder"
wget --output-document "$mboxfile" --continue https://"$mboxfile"
lastmboxsizeandnum="$(cat "$mboxfolder/lastmboxsizeandnum" 2>/dev/null || true)"
if [ "$lastmboxsizeandnum" = '' ]
then
    lastmboxsize=0
    lastmboxnum=0
else
    lastmboxsize=$((${lastmboxsizeandnum% *}))
    lastmboxnum="${lastmboxsizeandnum#* }"
fi
nextmboxsize="$(stat -c %s "$mboxfile")"

# install mailparser
if ! [ -e node_modules/mailparser ]
then
    npm install git+https://github.com/nodemailer/mailparser\#9bde04984d766fa4a47d0324b59509b78430e3ac
fi

# remove old tmp files
find "$mboxfolder" -name 'mbox-tmp-*' -exec rm -v '{}' +

# process new emails
if ((nextmboxsize != lastmboxsize))
then
    {
        tail -c +$((lastmboxsize)) "$mboxfile" 
        # mboxformat puts a \n between every email
        # this adds it to the last one, so it's the same as the others
        echo -ne '\n'
    } | csplit --elide-empty-files --digits 7 --prefix "$mboxfolder/mbox-tmp-" - '/^From .*[0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] [0-9][0-9][0-9][0-9]/' '{*}'
fi
nextmboxcount="$(find "$mboxfolder" -name 'mbox-tmp-*' | wc -l)"
./mbox_extracted_rename.nodejs "$mboxfolder" 'mbox-tmp-[0-9]*$'
#node - <<SCRIPTEND
#SCRIPTEND
#find "$mboxfolder" -name 'mbox-tmp-*' | while read mboxtmpfile
#do
#    num="${mboxtmpfile##*/mbox-tmp-}"
#    num="$(expr "$num" + "$lastmboxnum" || true)" # expr removes leading 0s during addition
#    mtime="$(sed -ne 's/^Date: \(.*\)$/\1/p' "$mboxtmpfile" | head -n 1)"
#    mtime="$(date --date="$mtime" +%s)"
#    muserhost="$(node - <<EOF
#require('mailparser').simpleParser(require('fs').readFileSync('$mboxtmpfile')).then(result=>console.log(result.from.value[0].address.replace('@','_')))
#EOF
#)"
#    #muserhost="$(sed -ne 's/^From: "*\([^"]*\)"* <\([^<@]*\)@\([^>]*\)>$/\2_\3/p; s/^From: \([^@ ]*\)@\([^ ]*\)$/\1_\2/p;' "$mboxtmpfile" | head -n 1)"
#    mv "$mboxtmpfile" "$mboxfolder"/"${mtime}_$muserhost".txt -v
#    [ "$muserhost" != '' ]
#done

echo "$((nextmboxsize)) $((lastmboxnum + nextmboxcount))" > "$mboxfolder"/lastmboxsizeandnum
