#!/usr/bin/env bash
set -euo pipefail
cd /workspace/labs/04-weather
run_id="$(date +%Y%m%d-%H%M%S)-$$"
build="/tmp/weather-$run_id"
mkdir -p "$build" /workspace/artifacts
javac -cp "$(hadoop classpath --glob)" -d "$build" Weather.java
jar cf "$build/weather.jar" -C "$build" .
hdfs dfs -mkdir -p /lab/input/weather
hdfs dfs -put -f "${WEATHER_INPUT:-weather.csv}" /lab/input/weather/weather.csv
output="/lab/output/weather-$run_id"
hadoop jar "$build/weather.jar" Weather /lab/input/weather/weather.csv "$output" "${1:-25}"
hdfs dfs -cat "$output/part-*" | tee /workspace/artifacts/weather-result.tsv
echo "Saved in HDFS: $output"
