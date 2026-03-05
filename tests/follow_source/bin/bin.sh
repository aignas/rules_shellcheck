#!/bin/bash
set -euo pipefail

# Source the external library (same directory in runfiles).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib1/lib1.sh"

hello_from_lib1
echo "Done"
