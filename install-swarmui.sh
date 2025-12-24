#!/bin/bash

set -e

echo "========================================================"
echo "SwarmUI Installation"
echo "========================================================"
echo ""

cd ${WORKSPACE:-/workspace}

# Clone SwarmUI
echo "Cloning SwarmUI repository..."
git clone https://github.com/mcmonkeyprojects/SwarmUI || true

cd SwarmUI

# Pull latest changes if already exists
git pull || true

echo ""
echo "SwarmUI cloned successfully!"
echo "SwarmUI will be configured to use external ComfyUI instance at localhost:8188"
echo ""

