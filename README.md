# HStackAntivirus
Online virus-checking service based on yara rules

## Usage
If you see this, you have already opened DefenderCode. Enjoy!

Click on the icon of file then select one or just attach it under the icon
If you wish to receive email message with result, tick corresponding checkbox and enter address.
After that click "Сканировать файл".
To remove added file, click 'X' button.

## How to build
Server runs on Debian-based Linux distro, but other distros are also possible.
Kernel version >= 4.18.
System requires at least 10 GB of free disk space, 1 GB of RAM and good Internet connection.

### Installation
1. Install haskell-stack via your package manager
2. Unpack rules.tar and yara.tar to parent directory
3. install yara
4. Add these files to project folder:
    * config.conf with login and password to your smtp mail service
    * cert.pem, privkey.pem, and rootCA.crt - SSL credentials
5. $ stack run
6. Open URL in browser
7. Enjoy!

### Yara installation
1. Install libraries (dev versions): jansson, libssl, openssl
2. Inside of yara folder run:
```console
$ ./bootstrap.sh
$ ./configure --enable-cuckoo --enable-dotnet --enable-magic --with-crypto
$ make
$ (sudo) make install
```
3. Check $ yara --version

### Rules preprocessing
```console
$ ./index_gen.sh
$ yara -w index.yar \<some file\>
```
If there are error file links, comment them in index.yar
