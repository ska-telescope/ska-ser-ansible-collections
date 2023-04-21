# Notes for velero restore

```
velero restore create test \
    --from-backup  every6h-20221021144151 \
    --existing-resource-policy=update \
    --exclude-namespaces kube-system,ingress-nginx,kube-node-lease,kube-public,metallb-system,velero  \
    --include-cluster-resources=true
```

# Check restore
```
velero restore describe test
```

# Get logs
```
kubectl -n velero logs $(kubectl -n velero get pods -l component=velero  -o name) > logs.txt
```