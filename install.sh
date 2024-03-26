#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
if ! [[ "${BASH_SOURCE[0]}" == "${0}" ]];then
	PREFIX="devkit.in"
else
	PREFIX="$PWD"
fi
install -v -D -C $PREFIX/content/devkit.sh /usr/local/bin/devkit
cp -pnv $PREFIX/content/devkit.conf /usr/local/etc/devkit.conf
