#!/bin/bash 
notification_url=https://heartbeat.uptimerobot.com/m787767935-6c18b1c3356566b927f3484dc8bc662b536dde5d
interval="1h"
url="http://192.168.99.154:9090/api/v1/query"

query=`curl -s --data-urlencode "query=sum(increase(gitlab_runner_errors_total{level =~ \"error|fatal|panic\"}[${interval}]))" "${url}"`
gitrst=`echo "${query}" | jq -r .data.result[0].value[1]`

echo "Start: " $(date)
echo "query: "$(echo "${query}" | json_pp)
echo "gitrst: ${gitrst}"

if [ "$gitrst" = "0" ]; then 
   wget --spider $notification_url >/dev/null 2>&1
   echo "updated UpTimeRobot"
else
   echo "Did not update UpTimeRobot"
fi

