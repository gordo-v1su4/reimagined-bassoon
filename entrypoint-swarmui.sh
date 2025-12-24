#!/bin/bash

set -e

WORKSPACE=${WORKSPACE:-/workspace}
SWARMUI_DIR="${WORKSPACE}/SwarmUI"
COMFYUI_HOST="${COMFYUI_HOST:-comfyui}"
COMFYUI_PORT="${COMFYUI_PORT:-8188}"

# Function to handle shutdown
cleanup() {
    echo ""
    echo "Shutting down SwarmUI..."
    
    # Kill SwarmUI if running
    if [ ! -z "$SWARMUI_PID" ]; then
        echo "Stopping SwarmUI (PID: $SWARMUI_PID)..."
        kill $SWARMUI_PID 2>/dev/null || true
        wait $SWARMUI_PID 2>/dev/null || true
    fi
    
    # Kill any processes on port 7801
    fuser -k 7801/tcp 2>/dev/null || true
    
    echo "SwarmUI stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI at ${COMFYUI_HOST}:${COMFYUI_PORT}..."
for i in {1..60}; do
    if curl -f -s "http://${COMFYUI_HOST}:${COMFYUI_PORT}/" > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "Warning: ComfyUI not ready after 60 attempts. Starting SwarmUI anyway..."
    fi
    sleep 2
done

# Start SwarmUI
echo "Starting SwarmUI..."
cd "${SWARMUI_DIR}"

# Launch SwarmUI in headless mode, pointing to external ComfyUI
# SwarmUI will connect to ComfyUI via the service name 'comfyui' on port 8188
./launch-linux.sh --launch_mode none --host 0.0.0.0 &
SWARMUI_PID=$!

echo "SwarmUI started (PID: $SWARMUI_PID) on port 7801"
echo ""
echo "Services:"
echo "  - SwarmUI: http://localhost:7801"
echo "  - ComfyUI: http://${COMFYUI_HOST}:${COMFYUI_PORT}"
echo ""
echo "Press Ctrl+C to stop SwarmUI"

# Wait for SwarmUI process
wait $SWARMUI_PID

