#!/bin/bash
# Generate Linux screenshots for both Tcl 8.6 and 9.0
#
# Usage: ./scripts/linux-screenshots.sh
#
# After running, bless with: rake screenshots:bless:linux

set -e

cd "$(dirname "$0")/.."

GENERATE_CMD="Xvfb :99 -screen 0 1024x768x24 & sleep 1 && DISPLAY=:99 rake screenshots:generate"

echo "=== Building Tcl/Tk 9.0 image ==="
docker build -f Dockerfile.ci-test -t tk-ci-test-9 .

echo ""
echo "=== Building Tcl/Tk 8.6 image ==="
docker build -f Dockerfile.ci-test --build-arg TCL_VERSION=8.6 -t tk-ci-test-8 .

echo ""
echo "=== Generating Tcl/Tk 9.0 screenshots ==="
docker run --rm -v "$(pwd)/screenshots:/app/screenshots" tk-ci-test-9 bash -c "$GENERATE_CMD"

echo ""
echo "=== Generating Tcl/Tk 8.6 screenshots ==="
docker run --rm -v "$(pwd)/screenshots:/app/screenshots" tk-ci-test-8 bash -c "$GENERATE_CMD"

echo ""
echo "=== Done ==="
echo "Screenshots generated in:"
echo "  screenshots/unverified/linux/tcl9.0/"
echo "  screenshots/unverified/linux/tcl8.6/"
echo ""
echo "To bless: rake screenshots:bless:linux"
