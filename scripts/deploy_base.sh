#!/bin/bash
cp *.sh /root
echo "forking to configure-ave-azs.sh, monitor install.log for root or AVIGUI"
su root -c "nohup /root/configure-ave-azs.sh >/dev/null 2>&1 &"