#!/bin/bash
#
# Record a Tk sample inside Docker and save to recordings/
#
# Usage:
#   ./scripts/docker-record.sh sample/demos-en/goldberg.rb
#   ./scripts/docker-record.sh sample/tkballoon-sample.rb
#
#   Options:
#     TCL_VERSION=8.6 ./scripts/docker-record.sh ...  # Use Tcl 8.6
#     CODEC=vp9 ./scripts/docker-record.sh ...        # Use vp9 (.webm)
#     SCREEN_SIZE=800x600 ./scripts/docker-record.sh ...
#
set -e

SAMPLE="${1:?Usage: $0 <sample.rb>}"
TCL_VERSION="${TCL_VERSION:-9}"
CODEC="${CODEC:-x264}"
IMAGE="tk-ci-test-${TCL_VERSION}"

[ -f "$SAMPLE" ] || { echo "Error: $SAMPLE not found"; exit 1; }

# Output filename with correct extension
BASENAME="${SAMPLE##*/}"
BASENAME="${BASENAME%.rb}"
case "$CODEC" in
    vp9) EXT="webm" ;;
    x264|h264) EXT="mp4" ;;
    *) EXT="webm" ;;
esac
OUTPUT="${BASENAME}.${EXT}"

# Ensure recordings dir exists
mkdir -p recordings

echo "Recording ${SAMPLE} with ${IMAGE} (${CODEC})..."

docker run --rm \
    -e "SCREEN_SIZE=${SCREEN_SIZE:-850x700}" \
    -e "FRAMERATE=${FRAMERATE:-30}" \
    -e "CODEC=${CODEC}" \
    -v "$(pwd)/scripts:/app/scripts:ro" \
    -v "$(pwd)/sample:/app/sample:ro" \
    -v "$(pwd)/lib/tk.rb:/app/lib/tk.rb:ro" \
    -v "$(pwd)/recordings:/app/recordings" \
    "${IMAGE}" \
    bash -c "./scripts/record-sample.sh '${SAMPLE}' && mv '${OUTPUT}' recordings/"

echo "Done: recordings/${OUTPUT}"
