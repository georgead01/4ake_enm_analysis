#!/bin/sh

# startup.command
# This is the script executed by VMDLauncher to actually start VMD.

p="$(dirname "$0")"

"${p}/../vmd2/lib/vmd_MACOSXARM64" $*

