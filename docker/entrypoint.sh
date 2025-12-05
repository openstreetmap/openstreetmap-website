#!/bin/sh
set -e

# Start Xvfb in the background for headless browser testing
export DISPLAY=:99.0
Xvfb $DISPLAY -screen 0 1024x768x24 &

# main command
exec "$@"
