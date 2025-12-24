#!/bin/bash

set -e

echo "========================================================"
echo "Building SwarmUI + ComfyUI Docker Image"
echo "========================================================"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found. Please run this script from the project root."
    exit 1
fi

echo "Building Docker image..."
docker build -t swarmui-comfyui:latest .

echo ""
echo "Build complete!"
echo ""
echo "To run the container:"
echo "  docker-compose up -d"
echo ""
echo "Or manually:"
echo "  docker run -d -p 7801:7801 -p 3000:3000 swarmui-comfyui:latest"

