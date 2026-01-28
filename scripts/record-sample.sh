#!/bin/bash
#
# Record a Tk sample to video
# Requires: xvfb-run (or DISPLAY set), ffmpeg
#
# The sample must handle TK_RECORD=1 for auto-start and auto-exit.
#
# Usage:
#   ./scripts/record-sample.sh sample/demos-en/goldberg.rb [output.webm]
#
#   Custom settings:
#     SCREEN_SIZE=1024x768 ./scripts/record-sample.sh sample/foo.rb
#     CODEC=x264 ./scripts/record-sample.sh sample/foo.rb  # h264, larger files
#
set -e

SAMPLE="${1:?Usage: $0 <sample.rb> [output]}"
SCREEN_SIZE="${SCREEN_SIZE:-900x750}"
FRAMERATE="${FRAMERATE:-30}"
CODEC="${CODEC:-x264}"  # x264 (default), vp9 (alternative)

# Output filename and codec settings
# Use NAME env var if provided, otherwise derive from sample path
if [ -n "$NAME" ]; then
    BASENAME="$NAME"
else
    BASENAME="${SAMPLE##*/}"
    BASENAME="${BASENAME%.rb}"
fi

case "$CODEC" in
    vp9)
        EXT="webm"
        CODEC_OPTS="-c:v libvpx-vp9 -crf 30 -b:v 0"
        ;;
    x264|h264)
        EXT="mp4"
        CODEC_OPTS="-c:v libx264 -preset fast -crf 23"
        ;;
    *)
        echo "Error: Unknown codec '$CODEC' (use vp9 or x264)"
        exit 1
        ;;
esac

OUTPUT="${2:-${BASENAME}.${EXT}}"

[ -f "$SAMPLE" ] || { echo "Error: $SAMPLE not found"; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "Error: ffmpeg not installed"; exit 1; }

# Use bundle exec if Gemfile present (Docker), otherwise plain ruby
if [ -f Gemfile ]; then
    RUBY_CMD="bundle exec ruby -Ilib"
else
    RUBY_CMD="ruby -Ilib"
fi

# If no DISPLAY, re-exec under xvfb-run
if [ -z "$DISPLAY" ]; then
    command -v xvfb-run >/dev/null 2>&1 || { echo "Error: xvfb-run not installed and DISPLAY not set"; exit 1; }
    exec xvfb-run -a -s "-screen 0 ${SCREEN_SIZE}x24" "$0" "$@"
fi

# Only print if not called from docker-record.sh
[ -z "$DOCKER_RECORD" ] && echo "Recording ${SAMPLE} to ${OUTPUT} (${SCREEN_SIZE}, ${CODEC})..."

# Create pipe for early stop signal
STOP_PIPE=$(mktemp -u)
mkfifo "$STOP_PIPE"
trap 'rm -f "$STOP_PIPE"' EXIT

# Thumbnail path (same name as output, .png extension)
THUMBNAIL="${OUTPUT%.*}.png"

# Start app with stop pipe FD and thumbnail path
TK_RECORD=1 TK_STOP_PIPE="$STOP_PIPE" TK_THUMBNAIL_PATH="$THUMBNAIL" $RUBY_CMD -rtk "$SAMPLE" &
APP_PID=$!

# Wait for window to appear (--sync blocks until found)
echo "Waiting for window..."
xdotool search --sync --onlyvisible --name "" >/dev/null
echo "Window detected, starting recording..."
sleep 0.3  # Brief settle time

ffmpeg -y -f x11grab -video_size ${SCREEN_SIZE} \
    -framerate ${FRAMERATE} -i ${DISPLAY} \
    ${CODEC_OPTS} \
    "${OUTPUT}" 2>/dev/null &
FFMPEG_PID=$!

# Wait for stop signal OR app exit
read -t 60 <"$STOP_PIPE" &
WAIT_PID=$!

# Whichever comes first
wait -n $APP_PID $WAIT_PID 2>/dev/null || true
echo "Stopping recording..."
kill $FFMPEG_PID 2>/dev/null || true
wait $FFMPEG_PID 2>/dev/null || true
wait $APP_PID 2>/dev/null || true

echo "Done: ${OUTPUT}"
