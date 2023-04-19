#!/bin/sh

ENDPOINT={{ cron_etcd_endpoint }}:2379
BACKUPDIR=/var/lib/backup
DTE=`date +"%Y.%m.%d.%H%M%S"`
AGE=8

SNAPSHOT=${BACKUPDIR}/k8s-etcd-snapshot-${DTE}.db

sudo mkdir -p ${BACKUPDIR}

# backup etcd
sudo ETCDCTL_API=3 /usr/bin/etcdctl --endpoints ${ENDPOINT} \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt  \
     --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
     --key=/etc/kubernetes/pki/etcd/healthcheck-client.key  \
     snapshot save ${SNAPSHOT}

# print the status of the backup
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status ${SNAPSHOT}

# compress backup
gzip -9 ${SNAPSHOT}

# prune old backups
echo "Pruning files older than ${AGE} days"
find ${BACKUPDIR} -type f -mtime +${AGE} -print
find ${BACKUPDIR} -type f -mtime +${AGE} -exec rm -rf {} \;

echo "Backup files:"
ls -latr ${BACKUPDIR}
