Collection of some work towards archiving cypherpunks list content on the BSV blockchain.

1993-July
thread: https://bico.media/15dbfa08f946abee4ddb80dd33e446dd2fd7a64ef550eeb5cccbd2cb4b7ffd02
subject: https://bico.media/0f8c72317153e8f8445531e9ba7a7f396de8147de494022bdbe6d64db7f43aee
author: https://bico.media/c524d0b0c6cbcaf79da488b3139722defeaa02bbe12611189f1e5eab74ca3dd4
date: https://bico.media/aa591274a0e1903a8d498148860d4f28a1a384155302c7c109f28c48fbcca666

2020-May
thread https://bico.media/22f71230126da9890a28c4573042564766af2afa4d68e6a7e3157105d62de4ab
subject https://bico.media/87d1b8c8558705efbf485c1a798bb025dd8057a2554cbbb49c2e0f2c57ea7dc6
author https://bico.media/15d913339bb52987bba846997b8f2a5bdd6c02b51b55fa51cdafaad3f0ea4378
date https://bico.media/2050b213eeedd633a493a11e7fa7cabf9b58ed1dde06b686cfd1521ad4f16159

2020-September
thread: https://bico.media/fc7c921b86c472b77b257d173214ccfa1f58fcdf277ff1485467efd1dbf0b96d
subject: https://bico.media/db0eaadf2fcd41122a69d10db468be3e2aefc2f2dd75bf83596ecf23e3e130de
author: https://bico.media/0b555ddb070ba3e534c3740ed7e7138c2144c8a7a940bdda9565c5e40cf7c81a
date: https://bico.media/ccc59927519c7788920555bba1a6e2f6a59734f6399fc081ec537fb4cf3ea71d

The private key is in this repository, encrypted with something I found on the list.

The BSV account the data is stored on is 12pfsqGm1Uc76BLbpUdR47jJehmwhThYck .

A nodejs tool called 'bsvup' is used by the upload script.  It still uses an
api server instead of the p2p network.

The script 'month.bash' downloads bsvup with npm and archives a single month
using the account.  It must be modified for the month in question.  It doesn't
at this time check that nobody else using the account, so avoid double-spends.

This is messy because I was confused.  The hope is to produce an immutable index
of the messages.


