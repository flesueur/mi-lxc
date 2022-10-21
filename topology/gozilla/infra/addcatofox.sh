#!/bin/bash

CERTFILE=$1

cp $1 /var/www/html/root.crt
chown www-data /var/www/html/root.crt
