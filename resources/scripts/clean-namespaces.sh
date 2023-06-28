#!/bin/bash

DECODED_INPUT=$(echo $1 | base64 -d | xargs)
SHARED_NAMESPACE_REGEX="^dev-shared-"

for RULE in $DECODED_INPUT; do
        AGE=$(echo $RULE | sed 's#.*:\([0-9]\+\)$#\1#')
        REGEX=$(echo $RULE | sed 's#:[0-9]\+$##')
        echo "Terminating all namespaces matching '$REGEX' older than '$AGE' seconds."
        NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$REGEX" --arg age $AGE -r '.items[] | select ((now - (.metadata.creationTimestamp | fromdateiso8601)) > ($age|tonumber)) | select(.metadata.name | test($regex)).metadata.name')
        for NS in $NAMESPACES; do
                kubectl delete namespace $NS
        done
done

echo "Terminating any shared namespaces that have an expired TTL"
NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$SHARED_NAMESPACE_REGEX" -r '.items[] | select(.metadata.annotations.SKA_SHARED_ENV_TTL) and (.metadata.annotations.SKA_SHARED_ENV_TTL | fromdateiso8601) < now) |  select(.metadata.name | test($regex)).metadata.name')
for NS in $NAMESPACES; do
	kubectl delete namespace $NS
done
