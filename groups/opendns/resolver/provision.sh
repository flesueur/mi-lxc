#!/bin/bash
# OpenDNS resolver
set -e
if [ -z $MILXCGUARD ] ; then exit 1; fi
DIR=`dirname $0`
cd `dirname $0`

# Be an open dns resolver
mkdir -p /etc/unbound/unbound.conf.d
echo -e "server:
	interface: 0.0.0.0
  access-control: 0.0.0.0/0 allow
" > /etc/unbound/unbound.conf.d/listen.conf
