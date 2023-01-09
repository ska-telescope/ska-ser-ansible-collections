#!/bin/bash 
test_url=localhost
test_port=1194
notification_url=https://heartbeat.uptimerobot.com/m787767907-af27b857315cf9a7195e6a82213f5790549e845e
vpnst=`nc -z -v -u -w 3 $test_url $test_port   2>&1 | grep succeeded`

echo "Start: " $(date)
echo "vpnst: ${vpnst}"

if [ "$#vpnst" != "0" ]; then 
   wget --spider $notification_url >/dev/null 2>&1
   #echo "$vpnst"
fi
