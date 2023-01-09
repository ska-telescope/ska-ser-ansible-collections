#!/bin/sh
HOURS=2
EXE=/tmp/checkage.py

echo ""; echo "Start: $(date)"
cat <<EOF >${EXE}
#!/usr/bin/python3
import sys
from datetime import datetime, timedelta
for line in sys.stdin:
 (name, ts) = line.split("\t")
 ts = datetime.strptime(ts.strip(), '%Y-%m-%dT%H:%M:%SZ')
 mark = datetime.now() - timedelta(hours=int(sys.argv[1]))
 if mark > ts:
  print(name)
EOF
# find the ones that are more than hours (defined as variable) old and begin with ci-*
kubectl get Namespace -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.metadata.creationTimestamp}{'\n'}{end}" | \
 python3 ${EXE} ${HOURS} | grep -E '^ci|^skampi|^test|^stress-skampi' | xargs kubectl delete ns
echo "End: $(date)"