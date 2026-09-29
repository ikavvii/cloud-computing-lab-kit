#!/usr/bin/env bash
set -euo pipefail
cd /workspace/labs/05-pig
output="/lab/output/flagged-$(date +%Y%m%d-%H%M%S)-$$"
hdfs dfs -mkdir -p /lab/input/catalog
hdfs dfs -put -f products.csv reviews.csv /lab/input/catalog/
pig -x mapreduce -logfile /workspace/artifacts/pig-details.log -param "OUTPUT=$output" -param "CATEGORY=${1:-Electronics}" -param "THRESHOLD=${2:-3.0}" inventory.pig
hdfs dfs -cat "$output/part-*" | tee /workspace/artifacts/pig-result.tsv
echo "Saved in HDFS: $output"
