:; SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
:; "${SCRIPT_DIR}/gradlew" "$@"
:; exit $?

@echo off
"%~dp0gradlew.bat" %*
