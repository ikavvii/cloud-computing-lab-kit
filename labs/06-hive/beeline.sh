#!/usr/bin/env bash
set -euo pipefail
# Hive 4.2's JLine 3 requires a system terminal even for batch execution.
# Its file reader also mishandles redirected input; -e uses the SQL batch parser.
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:---enable-preview --enable-native-access=ALL-UNNAMED}"
export SHELL=/bin/bash
arguments=()
while (($#)); do
  if [[ "$1" == '-f' ]]; then
    [[ $# -ge 2 ]] || { echo 'Missing SQL file after -f' >&2; exit 2; }
    arguments+=(-e "$(cat -- "$2")")
    shift 2
  else
    arguments+=("$1")
    shift
  fi
done
# %q preserves argument boundaries, quotes, and newlines in SQL.
printf -v quoted_arguments ' %q' "${arguments[@]}"
exec script -q -e -c "exec /opt/hive/bin/beeline$quoted_arguments" /dev/null
