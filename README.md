# HStackAntivirus
Online virus-checking service based on yara rules

## Installation
1. Install haskell-stack via your package manager
2. Unpack my-rules.tar and my-yara.tar to parent directory
4. Check if URL in fetch function from main.js is valid
5. $ stack run
5. Open URL in browser
7. Enjoy!

## Yara installation
1. Install libraries (dev versions): jansson, libssl, openssl
2. Inside of yara folder run:
* $ ./bootstrap.sh
* $ ./configure --enable-cuckoo --enable-dotnet --enable-magic --with-crypto
* $ make
* $ make install
3. Check $ yara --version

## Rules preprocessing
- $ ./index_gen.sh
- $ yara index.yar \<some file\>
- Comment error lines in index.yar

## Documentation
Click on the icon of file then select one or just attach it under the icon
If you wish to receive email message with result, tick corresponding checkbox and enter address.
After that click on "Сканировать файл".
To remove added file, click on 'X' button.
