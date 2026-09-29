#!/usr/bin/env bash
set -euo pipefail
mkdir -p /tmp/cloudsim-classes /workspace/artifacts
javac -cp '/opt/cloudsim/lib/*' -d /tmp/cloudsim-classes /workspace/labs/03-cloudsim/MinMinScheduling.java
java -cp '/tmp/cloudsim-classes:/opt/cloudsim/lib/*' MinMinScheduling "${1:-minmin}" |
  tee "/workspace/artifacts/cloudsim-${1:-minmin}.txt"
