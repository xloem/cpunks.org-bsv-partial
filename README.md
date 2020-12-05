Collection of some work towards archiving cypherpunks list content on the BSV blockchain.

The private key is in this repository, encrypted with something I found on the list.

The BSV account the data is stored on is 12pfsqGm1Uc76BLbpUdR47jJehmwhThYck .

A nodejs tool called 'bsvup' is used by the upload script.

The scriptsuite is not complete.  Some manual operations are still involved.

The current process is to use `download_cpunks_archive.bash` to get the webpages,
then to modify and use `upload_archive_to_bsv.bash` to upload some of the data,
then to pass all the message paths to `mutate_paths_to_txlinks.bash` to remove
their inter-message links so they can be uniquely identified with transaction ids,
then to upload those, then to pass the index pages to the script and upload them.

This is confusing because I was confused.  The hope is to produce an immutable index
of the messages.
