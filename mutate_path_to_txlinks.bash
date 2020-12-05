#!/usr/bin/env bash

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
        # all the links in these documents span lines.
        # there's a glitch here that preserves the mailto links by incidence.
        sed '/<A HREF/ {N;s/\n//;}'
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
elif echo "$path" | grep 'mailman/listinfo'
# listinfo page, has a link to archives index, so should go near top of hierarchy
then
    # but for now we just remove all links, since so few messages are archived to form an index.
    link_removal_sed_match='\(.*\)'
    preprocess() {
        sed '/<a href/ {N;s/\n//;}'
    }
else
    echo "Don't recognise this kind of path for link mutation" 1>&2
    exit -1
fi >/dev/null

filter_links() {
    sed "s/<[aA] [hH][rR][eE][fF]=['\"]$link_removal_sed_match['\"]>\([^<]*\)<\/[aA]>/\2/g"
}

extract_links() {
    sed -ne "s/.*<[aA] [hH][rR][eE][fF]=[\"']\\([^\"'\#]*\\).*/\1/p"
}

tx_paths_to_txids() {

    # if there are multiple uploads to the same path, this will output all of them,
    # rather than the latest or earliest, which will result in always the same random one being selected.
    # a quick workaround is to delete all but one.

    # this situation is not presently detected.  but a solution could be to remove the txid component from the output, and pipe it to sort and uniq and verify the linecount is the same.

    for tx in .bsv/tx/*
    do
        xxd -r -ps "$tx" | strings
    done | sed -ne 's/.*19iG3WTYSsbyos3uJ733yK4zEioi1FesNU.\(.*\)@\([0-9a-fA-F]*\)/\1 \2/p'
}

txid_for_path() {
    path="$1"
    entry="$(grep "^$path" linkmap.list 2>/dev/null)"
    if [ "$entry" = '' ]
    then
        tx_paths_to_txids > linkmap.list
        entry="$(grep "^$path" linkmap.list 2>/dev/null)"
    fi
    echo "${entry##* }" # last chunk of text without spaces in it, so spaces in paths shouldn't break it
}

add_reference_to_original() {
    txid="$(txid_for_path "$path")"
    sed 's!<[bB][oO][dD][yY][^>]*>!&<i>This page was mutated from <a href="'"/$txid"'">its original content</a> to reduce and change some links that could confuse integrity.</i>!'
}

is_relative() {
    path="$1"
    # starts without /
    [ "${path#/}" = "$path" ] &&
    # starts without https:// or https://
    [ "${path#http://}" = "$path" ] && [ "${path#https://}" = "$path" ]
}

txlinkof() {
    path="$1"
    basepath="$(basename "$path")"
    if [ "${basepath%.*}" != "$basepath" ]
    # has a .something suffix
    then
        echo "${path%.*}.txlink.${path##*.}"
    else
        echo "$path".txlink
    fi
}

link_mutation_sed_script() {
    cat "$path" | preprocess | filter_links | extract_links | while read link
    do
        # skip mailto links of course
        if echo "$link" | grep "^mailto:"  2>/dev/null
        then
            continue
        fi

        original_link="$link"
        if [ "${link#http://}" != "$link" ] || [ "${link#https://}" != "$link" ]
        then
            # if hostname differs from first pathname component, seems fine to skip mutation
            skip_safely=1
        else
            skip_safely=0
        fi
        if is_relative "$link"
        then
            link="$relprefix$link"
        fi
        link="${link#http://}"
        link="${link#https://}"
        txid="$(txid_for_path "$(txlinkof "$link")")"
        if [ "$txid" = '' ]
        then
            if ((skip_safely))
            then
                continue
            fi
            echo 'No map for link '"$link"' as '"$(txlinkof "$link")" 1>&2
            echo 'Maybe mutate and upload it first?' 1>&2
            echo 'Note, atm this only works if uploading has completed.' 1>&2
            echo 'If this is an issue just replace this output and termination with a "continue" statement I suppose.' 1>&2
            echo 'That will skip mutation of missing links.' 1>&2
            exit -1
        fi
        # double quote used for delimiter hopefully works with html situation
        echo "s\"$original_link\"/$txid\"g;"
    done
}

sedscript="$(mktemp)"
link_mutation_sed_script > sedscript || {
    rm "$sedscript"
    exit -1
}

mutate_links() {
    sed -f "$sedscript"
    cat "$sedscript" 1>&2
    rm "$sedscript"
}

output="$(txlinkof "$path")"

cat "$path" | preprocess | filter_links | mutate_links | add_reference_to_original > "$output"

echo "Made $output"
