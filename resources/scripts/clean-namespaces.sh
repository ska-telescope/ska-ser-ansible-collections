#!/bin/bash

if [ $# -ne 2 ]; then
        echo "ERROR: Script takes exactly 2 arguments: the initial part of the string for all namespaces to delete and the maximum age of the namespaces in seconds."
        exit 1
fi

NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$1" --arg age $2 -r '.items[] | select ((now - (.metadata.creationTimestamp | fromdateiso8601)) > ($age|tonumber)) | select(.metadata.name | test($regex)).metadata.name')

echo "Terminating all namespaces with regex='$1' and age older than $2 seconds."
for NS in $NAMESPACES
do
        kubectl delete namespace $NS
done
