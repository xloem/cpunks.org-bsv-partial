#!/usr/bin/env bash

echo 'WIP.  Just outputs debugging information now, without doing anything.'

address='12pfsqGm1Uc76BLbpUdR47jJehmwhThYck'

path="$1"
path="$(realpath --relative-to=. "$path")"
relprefix="$(dirname "$path")/"
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
    echo "Don't recognise this kind of path for link mutation" 1>&2
    exit -1
fi >/dev/null

filter_links() {
    sed "s/<a [hH][rR][eE][fF]=['\"]$link_removal_sed_match['\"]>\([^<]*\)<\/a>/\2/g"
}

extract_links() {
    sed -ne "s/.*[hH][rR][eE][fF]=[\"']\\([^\"'\#]*\\).*/\1/p"
}

tx_paths_to_txids() {
    for tx in .bsv/tx/*
    do
        xxd -r -ps "$tx" | strings
    done | sed -ne 's/.*19iG3WTYSsbyos3uJ733yK4zEioi1FesNU.\(.*\)@\([0-9a-fA-F]*\)/\1 \2/p'
}

is_relative() {
    path="$1"
    # starts without /
    [ "${path#/}" = "$path" ]
}

cat "$1" | preprocess | filter_links | extract_links | while read link
do
    if is_relative "$link"
    then
        link="$relprefix$link"
    fi
    linkentry="$(grep "^$link" linkmap.list 2>/dev/null)"
    if [ "$linkentry" = '' ]
    then
        tx_paths_to_txids > linkmap.list
        linkentry="$(grep "^$link" linkmap.list)"
    fi
    if [ "$linkentry" = '' ]
    then
        echo 'No map for link '"$link" 1>&2
        echo 'If this is an issue just replace this output and termination with a "continue" statement I suppose.' 1>&2
        exit -1
    fi
    echo "$linkentry"
done
