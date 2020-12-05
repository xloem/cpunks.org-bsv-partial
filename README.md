Collection of some work towards archiving cypherpunks list content on the BSV blockchain.

2020-September
author: https://bico.media/fedd0a8368dd68ae495279094435391f0e13291866af7a8a26aa182028af2df6
date: https://bico.media/bd7fb31a5d7e685fcba3892fd28a7e4f7cc35c57576e7a7812a68746e48c15f1
subject: https://bico.media/4fe2cc266634e04401d27e366529b83c1f61cecf7767ab53f4b426dcc0590970
thread: https://bico.media/a41c50edfa8fc0c46d0f46ae82ac8c65e9f925f5c5a731006cb421318cd524e6

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

The process after downloading is bundled into the untested `archive_month.bash`
script, which takes a path to a subfolder within
lists.cpunks.org/pipermail/cypherpunks/* as an argument.
