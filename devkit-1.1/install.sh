#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
if [ -f "$PWD/build.cfg" ];then
		echo "Can't install DevKit from source!"
		exit 1
fi
install -v -C -m 775 -o root $PWD/bin/devkit /usr/local/bin/devkit
if [ ! -f "/usr/local/etc/devkit.conf" ];then
	install -v -D -C -m 664 -o root $PWD/etc/devkit.conf /usr/local/etc/devkit.conf
fi
echo "Done."
