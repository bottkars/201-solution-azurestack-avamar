#!/bin/bash
tty
cp *.sh /root
su root -c "nohup /root/configure-ave-azs.sh >/dev/null 2>&1 &"