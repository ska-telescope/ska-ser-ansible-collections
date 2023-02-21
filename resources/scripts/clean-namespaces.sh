#!/bin/bash

if [ $# -ne 1 ]; then
        echo "Script takes exactly 1 argument: the regex selector for the name of the namespaces to delete"
        exit 1
fi

# First definitively kill all namespaces that are left dangling in Terminating status
# NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Terminating -o json | jq -r '.items[]
# | select(.metadata.name | test("'$1'")).metadata.name')

# echo "Forcibly terminating all namespaces left in dangling Terminating state."
# for NS in $NAMESPACES
# do
#         # echo $NS
#         kubectl get namespace $NS -o json \
#                 | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
#                 | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
# done

# Now ask nicelly so that all namespaces starting with the argument are deleted (if they don't delete correclty, next run of this script will get rid of them)
# NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$1" -r '.items[] | select(.metadata.name | test("'$regex'")).metadata.name')
NAMESPACES=$(kubectl get namespaces --field-selector status.phase=Active -o json | jq --arg regex "$1" -r '.items[] | select(.metadata.name | test($regex)).metadata.name')

echo "Terminating all $1* namespaces."
for NS in $NAMESPACES
do
        # echo $NS
        kubectl delete namespace $NS --dry-run=client
done
