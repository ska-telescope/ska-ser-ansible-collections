#!/bin/bash

read host
read ip
var=

while read oid val
do
  if [ "$vars" = "" ]
  then
    vars="$oid = $val"
  else
    vars="$vars, $oid = $val"
  fi
done

echo trap: $1 $host $ip $vars

echo "***************" >> /home/ubuntu/trap.log
echo trap: $1 >> /home/ubuntu/trap.log
echo host: $host >> /home/ubuntu/trap.log
echo ip: $ip >> /home/ubuntu/trap.log
echo vars: $vars >> /home/ubuntu/trap.log




