#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
install -v -C -m 775 -o root devkit.sh /usr/local/bin/devkit
if [ ! -f "/usr/local/etc/devkit.conf" ];then
	install -v -D -C -m 664 -o root devkit.conf /usr/local/etc/devkit.conf
fi
echo "Done."
