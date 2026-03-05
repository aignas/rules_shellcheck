#!/bin/bash

# Source the external library (same directory in runfiles).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib2/lib2.sh"

hello_from_lib() {
    echo "Hello from library 1"
    hello_from_lib2
}
