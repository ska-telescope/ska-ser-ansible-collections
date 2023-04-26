#!/bin/bash
set -x
test_url=localhost
test_port=1194
notification_url="{{ cron_vpn_notification_url }}"
vpnst=`nc -z -v -u -w 3 $test_url $test_port  2>&1 | grep succeeded`

echo "Start: " $(date)
echo "vpnst: ${vpnst}"

if [ "$#vpnst" != "0" ]; then
   wget --spider $notification_url >/dev/null 2>&1
fi
