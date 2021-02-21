#!/bin/bash
set -e

yum install -y perl tar gzip sudo perl-App-cpanminus ncurses-devel readline-devel gcc make
cpanm -n Term::ReadLine::Gnu

if [ ! -x "/usr/bin/patchelf" -a ! -x "/usr/local/bin/patchelf" ] ; then
	yum install -y git autoconf automake gcc-c++
	tdir=`mktemp -d`
	cd "$tdir"
	git clone https://github.com/NixOS/patchelf.git
	cd patchelf
	./bootstrap.sh
	./configure
	make
	make install
	cd /
	rm -rf "$tdir"
else
	echo "Found patchelf, no need to build it."
fi

if [ ! -x "/usr/bin/npm" -a ! -x "/usr/local/bin/npm" ] ; then
	# https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
	. ~/.nvm/nvm.sh
	nvm install node
else
	echo "Found npm, no need to install it."
fi

echo ""
echo ""
echo "Everything should be in order now!"
echo "Now you should be able to run vircadia-builder."
echo ""
