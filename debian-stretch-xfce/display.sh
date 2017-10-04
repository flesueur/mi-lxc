#!/bin/bash

Xnest -sss -name Xnest -display :0 :1 &
export DISPLAY=:1
setxkbmap fr
xfce4-session
