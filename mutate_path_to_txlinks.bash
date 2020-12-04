#!/usr/bin/env bash

echo 'WIP.  Just outputs debugging information now, without doing anything.'

address='12pfsqGm1Uc76BLbpUdR47jJehmwhThYck'

path="$1"
# different paths will have different sed filters

if echo "$path" | grep '/[0-9]*\.html'
# individual messages end in numbers
then
    # remove all links
    link_removal_sed_match='\(.*\)'
    preprocess() {
        cat
    }
elif echo "$path" | grep '/author\.html' || echo "$path" | grep '/date\.html' || echo "$path" | grep '/subject\.html' || echo "$path" | grep '/thread\.html'
# month index pages are author.html, date.html, etc
then
    # remove links to everything but individual messages, which start with a number
    link_removal_sed_match='\([^0-9].*\)'
    preprocess() {
        # a link spans a line here, so it is joined
        sed '/>More info on this list/ {N;s/\n//;}'
    }
else
    echo "Don't recognise this kind of path for link mutation"
    exit -1
fi

filter_links() {
    sed "s/<a [hH][rR][eE][fF]=['\"]$link_removal_sed_match['\"]>\([^<]*\)<\/a>/\2/g"
}

extract_links() {
    sed -ne "s/.*[hH][rR][eE][fF]=[\"']\\([^\"'\#]*\\).*/\1/p"
}

cat "$1" | preprocess | filter_links | extract_links | while read link
do
    bitfiles status d://"$address"/"$1"
done
