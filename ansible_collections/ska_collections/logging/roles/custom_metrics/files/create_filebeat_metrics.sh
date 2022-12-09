#!/bin/bash
NODE_EXPORTER_FOLDER="/var/lib/prometheus/node-exporter"
METRICS_FILE_NAME="filebeat.prom"
FILEBEAT_METRICS_PATH="${NODE_EXPORTER_FOLDER}/${METRICS_FILE_NAME}"
TMP_METRICS_PATH=$(mktemp)

# Create temporary log file
LOGFILE=$(mktemp)
podman logs --since 1m filebeat >> $LOGFILE 2>&1

# Calculate metrics
TIMESTAMP=$(date +%s)
INFO_LOGS=$(cat ${LOGFILE} | cut -f 2 | grep -c INFO)
WARN_LOGS=$(cat ${LOGFILE} | cut -f 2 | grep -c WARN)
ERROR_LOGS=$(cat ${LOGFILE} | cut -f 2 | grep -c ERROR)

# Write the number of firing logs per level
echo "# HELP node_filebeat_firing_logs The number of filebeat logs firing in the last minute." >> "${TMP_METRICS_PATH}"
echo "# TYPE node_filebeat_firing_logs gauge" >> "${TMP_METRICS_PATH}"
echo "node_filebeat_firing_logs{level=\"INFO\"} ${INFO_LOGS}" >> "${TMP_METRICS_PATH}"
echo "node_filebeat_firing_logs{level=\"WARN\"} ${WARN_LOGS}" >> "${TMP_METRICS_PATH}"
echo "node_filebeat_firing_logs{level=\"ERROR\"} ${ERROR_LOGS}" >> "${TMP_METRICS_PATH}"

# Write the timestamp of this check, useful to check if the cronjob is running normally
echo "# HELP node_filebeat_metrics_update_seconds The timestamp of the last filebeat metrics update." >> "${TMP_METRICS_PATH}"
echo "# TYPE node_filebeat_metrics_update_seconds counter" >> "${TMP_METRICS_PATH}"
echo "node_filebeat_metrics_update_seconds ${TIMESTAMP}" >> "${TMP_METRICS_PATH}"

# Atomically update the prometheus metrics file
mv "${TMP_METRICS_PATH}" "${FILEBEAT_METRICS_PATH}"
rm $LOGFILE