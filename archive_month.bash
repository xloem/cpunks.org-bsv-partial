#!/usr/bin/env bash
monthdir="$1"
bsvup --file "$monthdir" --subdirectory "$monthdir" --rate 500 upload
for message in "$monthdir"/0?????.html
do
    if ! ./mutate_path_to_txlinks.bash "$message"
    then
        exit -1
    fi
done
bsvup --file "$monthdir" --subdirectory "$monthdir" --rate 500 upload
for index in author date subject thread
do
    if ! ./mutate_path_to_txlinks.bash "$monthdir"/"$index".html
    then
        exit -1
    fi
done
bsvup --file "$monthdir" --subdirectory "$monthdir" --rate 500 upload
