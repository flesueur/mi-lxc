#!/bin/bash

wget http://www.gozilla.milxc/root.crt -O /usr/local/share/ca-certificates/root.crt
/usr/sbin/update-ca-certificates --fresh
