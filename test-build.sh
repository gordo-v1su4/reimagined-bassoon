#!/bin/bash

# Quick test to verify Docker and files are ready
echo "Testing build environment..."
echo ""

# Check Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker found: $(docker --version)"
else
    echo "✗ Docker not found"
    exit 1
fi

# Check files
echo ""
echo "Checking required files..."
for file in Dockerfile install-swarmui.sh entrypoint.sh; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file missing"
        exit 1
    fi
done

echo ""
echo "All files present. Ready to build!"
echo ""
echo "Run: docker build -t swarmui-comfyui:latest ."

