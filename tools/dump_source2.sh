#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Pass in game name"
	exit 1
fi

TOOLS_DIR="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
DUMPER_PATH="$TOOLS_DIR/DumpSource2/build/CS2Dumper"

cd "$TOOLS_DIR" || exit 1

GAME_DIR="$(realpath "../$1/game/bin/linuxsteamrt64/")"

cd "$GAME_DIR" || exit 1

# Create a stub of libvideo to avoid installing video dependencies
python3 "$TOOLS_DIR/implib/implib-gen.py" --no-dlopen libvideo.so
mv libvideo.so libvideo.so.original
gcc -DIMPLIB_EXPORT_SHIMS=1 -g -fPIC -shared libvideo.so.tramp.S libvideo.so.init.c -ldl -o libvideo.so
rm libvideo.so.tramp.S libvideo.so.init.c

# todo move cs2dumper
LD_LIBRARY_PATH="$GAME_DIR" timeout 2m "$DUMPER_PATH" || true

mv libvideo.so.original libvideo.so
