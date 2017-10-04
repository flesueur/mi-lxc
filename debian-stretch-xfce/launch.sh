#!/bin/bash

#LXCPATH=`lxc-config lxc.lxcpath`
DIR=`dirname $0`
#MYTMPDIR=`mktemp -d /tmp/lxcXXX`

CNAME="debian-stretch-xfce"

case $1 in
	create)
		cd $DIR
		DIRNAME=`pwd`
		cat $DIR/config > $DIR/config.tmp
		echo "lxc.mount.entry=$DIRNAME tmp/lxc none ro,bind,create=dir 0 0" >> $DIR/config.tmp 
		lxc-create -t download -n $CNAME -f $DIR/config.tmp -- -d debian -r stretch -a amd64
		lxc-start -n $CNAME
		lxc-attach -n $CNAME "/tmp/lxc/pre-provision.sh"
	;;
	provision)
		lxc-attach -n $CNAME "/tmp/lxc/pre-provision.sh"
	;;
	display)
		lxc-attach -n $CNAME "/tmp/lxc/display.sh"
	;;
	attach)
		lxc-attach -n $CNAME
	;;
	start)
		lxc-start -n $CNAME
	;;
	stop)
		lxc-stop -n $CNAME
	;;
	destroy)
		lxc-stop -n $CNAME
		lxc-destroy -n $CNAME
	;;
esac
