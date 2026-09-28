#!/usr/bin/env sh
set -eu

"$(dirname "$0")/check-prereqs.sh"
exec ores-compose up .ores-compose.yaml
