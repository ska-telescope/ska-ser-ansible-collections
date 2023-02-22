#!/bin/bash

DECODED_INPUT=$(echo $1 | base64 -d | xargs)
for RULE in $DECODED_INPUT; do
        AGE=$(echo $RULE | sed 's#.*:\([0-9]\+\)$#\1#')
        REGEX=$(echo $RULE | sed 's#:[0-9]\+$##')
        echo "Terminating all namespaces matching '$REGEX' older than '$AGE' seconds."
        NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$REGEX" --arg age $AGE -r '.items[] | select ((now - (.metadata.creationTimestamp | fromdateiso8601)) > ($age|tonumber)) | select(.metadata.name | test($regex)).metadata.name')
        for NS in $NAMESPACES; do
                kubectl delete namespace $NS --dry-run=client
        done
done
