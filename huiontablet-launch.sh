#!/bin/bash
script_path="${BASH_SOURCE[0]:-$0}"
script_path="$(readlink -f "$script_path" 2>/dev/null || echo "$script_path")"
appname="$(basename "$script_path")"
appname="${appname%.sh}"
dirname="$(dirname "$script_path")"

LD_LIBRARY_PATH=$dirname/libs
export LD_LIBRARY_PATH

QT_QPA_PLATFORM_PLUGIN_PATH=$dirname/plugins
export QT_QPA_PLATFORM_PLUGIN_PATH

QML2_IMPORT_PATH=$dirname/qml
export QML2_IMPORT_PATH

# Only match the actual binaries by exact process name (avoid matching this script or grep)
if pgrep -x huionCore >/dev/null; then
	killall huionCore >/dev/null 2>&1
	sleep 1
fi

if pgrep -x huiontablet >/dev/null; then
	killall huiontablet >/dev/null 2>&1
	sleep 1
fi

sleep 2

LOG_DIR="${HUION_LOG_DIR:-$HOME/.local/share/huiontablet}"
mkdir -p "$LOG_DIR"

# Run huionCore in background (suppress vendor stdout/stderr spam)
$dirname/huionCore -d >>"$LOG_DIR/huionCore.log" 2>&1 &

# Run huiontablet; redirect stdout and stderr to log so terminal stays clean
$dirname/$appname "$@" -d >>"$LOG_DIR/huiontablet.log" 2>&1
