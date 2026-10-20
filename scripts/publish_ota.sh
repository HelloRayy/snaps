#!/usr/bin/env bash
# ==============================================================================
# Wrapper script - forwards all arguments to ./scripts/auto_release.sh
# ==============================================================================
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/auto_release.sh" "$@"
