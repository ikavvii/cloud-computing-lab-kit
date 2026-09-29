#!/usr/bin/env bash
set -euo pipefail
mkdir -p /data/namenode /data/datanode /data/tmp
if [[ ! -f /data/namenode/current/VERSION ]]; then
  hdfs namenode -format -nonInteractive lab-cluster
fi
cleanup() {
  mapred --daemon stop historyserver || true
  yarn --daemon stop nodemanager || true
  yarn --daemon stop resourcemanager || true
  hdfs --daemon stop datanode || true
  hdfs --daemon stop namenode || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT
hdfs --daemon start namenode
hdfs --daemon start datanode
yarn --daemon start resourcemanager
yarn --daemon start nodemanager
mapred --daemon start historyserver
ready=0
for attempt in {1..90}; do
  if hdfs dfsadmin -safemode get 2>/dev/null | grep -q 'OFF' &&
     hdfs dfsadmin -report 2>/dev/null | grep -q 'Live datanodes (1)' &&
     yarn node -list 2>/dev/null | grep -q 'RUNNING'; then
    ready=1; break
  fi
  sleep 2
done
[[ "$ready" == 1 ]] || { tail -n 60 /opt/hadoop/logs/*.log; exit 1; }
hdfs dfs -mkdir -p /user/lab /lab/input /lab/output
touch /tmp/lab-ready
echo 'READY: HDFS + YARN + MapReduce JobHistory; Pig available. Use docker compose exec bigdata bash.'
while true; do
  for daemon in NameNode DataNode ResourceManager NodeManager JobHistoryServer; do
    jps | grep -q " $daemon$" || { echo "Daemon stopped: $daemon"; exit 1; }
  done
  sleep 15 & wait $!
done
