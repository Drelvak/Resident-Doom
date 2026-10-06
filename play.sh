#!/usr/bin/env sh
set -eu
cd -- "$(dirname -- "$0")"
if ! command -v python3 >/dev/null 2>&1; then echo 'Python 3.11+ is required.' >&2; exit 1; fi
exec python3 play.py "$@"
