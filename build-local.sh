#!/bin/bash

set -e

echo "========================================================"
echo "Building SwarmUI + ComfyUI Docker Image"
echo "========================================================"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Working directory: $(pwd)"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    echo "Please install Docker or ensure it's in your PATH"
    exit 1
fi

echo "Docker version:"
docker --version
echo ""

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found. Current directory: $(pwd)"
    exit 1
fi

echo "Found Dockerfile. Starting build..."
echo "This may take 30-60 minutes..."
echo ""

# Build the image
docker build -t swarmui-comfyui:latest . 2>&1 | tee build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}

echo ""
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "========================================================"
    echo "Build completed successfully!"
    echo "========================================================"
    echo ""
    echo "Image: swarmui-comfyui:latest"
    echo ""
    echo "To run the container:"
    echo "  docker-compose up -d"
    echo ""
    echo "Or manually:"
    echo "  docker run -d -p 7801:7801 -p 3000:3000 swarmui-comfyui:latest"
    echo ""
else
    echo "========================================================"
    echo "Build failed with exit code: $BUILD_EXIT_CODE"
    echo "========================================================"
    echo ""
    echo "Check build.log for details"
    echo "Last 50 lines of build.log:"
    tail -50 build.log
    exit $BUILD_EXIT_CODE
fi

