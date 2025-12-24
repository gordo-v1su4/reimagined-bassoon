#!/bin/bash

set -e

export UV_SKIP_WHEEL_FILENAME_CHECK=1
export UV_LINK_MODE=copy

echo "========================================================"
echo "ComfyUI Installation (Docker/Coolify)"
echo "========================================================"
echo ""

# Set non-interactive installation flags
install_ipadapter=true
install_reactor=false
install_impact=false

echo "Installation Summary:"
echo "  [X] ComfyUI_IPAdapter_plus"
echo "  [ ] ComfyUI-ReActor (skipped)"
echo "  [ ] ComfyUI-Impact-Pack (skipped)"
echo ""
echo "Starting installation..."
echo ""

cd ${WORKSPACE:-/workspace}

# Clone ComfyUI
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI

cd ComfyUI

git reset --hard
git stash || true
git pull --force || true

# Create venv
python3 -m venv venv

source venv/bin/activate

# Upgrade pip and install uv
python3 -m pip install --upgrade pip
python3 -m pip install uv

# Install PyTorch
uv pip install torch==2.8.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

# Install custom nodes
cd custom_nodes

# Required nodes
echo "Cloning ComfyUI-Manager..."
if ! git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager; then
    echo "Error: Failed to clone ComfyUI-Manager (required)"
    exit 1
fi

echo "Cloning ComfyUI-QuantOps..."
if ! git clone --depth 1 https://github.com/silveroxides/ComfyUI-QuantOps; then
    echo "Warning: Failed to clone ComfyUI-QuantOps, retrying..."
    rm -rf ComfyUI-QuantOps
    sleep 2
    if ! git clone --depth 1 https://github.com/silveroxides/ComfyUI-QuantOps; then
        echo "Error: Failed to clone ComfyUI-QuantOps after retry"
        exit 1
    fi
fi

# Clone ComfyUI_IPAdapter_plus
if [ "$install_ipadapter" = true ]; then
    echo "Installing ComfyUI_IPAdapter_plus..."
    if ! git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus; then
        echo "Warning: ComfyUI_IPAdapter_plus clone failed, retrying..."
        rm -rf ComfyUI_IPAdapter_plus
        sleep 2
        if ! git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus; then
            echo "Error: Failed to clone ComfyUI_IPAdapter_plus after retry"
            exit 1
        fi
    fi
fi

# Clone ComfyUI-GGUF
echo "Cloning ComfyUI-GGUF..."
if ! git clone --depth 1 https://github.com/city96/ComfyUI-GGUF; then
    echo "Warning: ComfyUI-GGUF clone failed, retrying..."
    rm -rf ComfyUI-GGUF
    sleep 2
    if ! git clone --depth 1 https://github.com/city96/ComfyUI-GGUF; then
        echo "Warning: ComfyUI-GGUF clone failed again, skipping..."
        mkdir -p ComfyUI-GGUF
    fi
fi

# Clone RES4LYF (with retry on failure)
echo "Cloning RES4LYF..."
if ! git clone --depth 1 https://github.com/ClownsharkBatwing/RES4LYF; then
    echo "Warning: RES4LYF clone failed, retrying..."
    rm -rf RES4LYF
    sleep 2
    if ! git clone --depth 1 https://github.com/ClownsharkBatwing/RES4LYF; then
        echo "Warning: RES4LYF clone failed again, skipping..."
        mkdir -p RES4LYF
    fi
fi

# Setup ComfyUI-Manager
cd ComfyUI-Manager
git stash || true
git reset --hard || true
git pull --force || true
uv pip install -r requirements.txt
cd ..

# Setup ComfyUI_IPAdapter_plus
if [ "$install_ipadapter" = true ]; then
    echo "Setting up ComfyUI_IPAdapter_plus..."
    cd ComfyUI_IPAdapter_plus
    git stash || true
    git reset --hard || true
    git pull --force || true
    cd ..
fi

# Setup ComfyUI-GGUF (only if clone succeeded)
if [ -d "ComfyUI-GGUF" ] && [ -f "ComfyUI-GGUF/.git/config" ]; then
    cd ComfyUI-GGUF
    git stash || true
    git reset --hard || true
    git pull --force || true
    if [ -f "requirements.txt" ]; then
        uv pip install -r requirements.txt
    fi
    cd ..
else
    echo "Skipping ComfyUI-GGUF setup (clone failed or incomplete)"
fi

# Setup RES4LYF (only if clone succeeded)
if [ -d "RES4LYF" ] && [ -f "RES4LYF/.git/config" ]; then
    cd RES4LYF
    git stash || true
    git reset --hard || true
    git pull --force || true
    if [ -f "requirements.txt" ]; then
        uv pip install -r requirements.txt
    fi
    cd ..
else
    echo "Skipping RES4LYF setup (clone failed or incomplete)"
fi

# Go back to ComfyUI directory (we're currently in custom_nodes)
cd ..

echo "Installing ComfyUI requirements..."

# Make sure we're in ComfyUI directory and venv is activated
source venv/bin/activate
uv pip install -r requirements.txt

# Uninstall xformers and install specific .whl files
uv pip uninstall xformers || true

# Install flash-attn (compatible with Python 3.10)
uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/flash_attn-2.8.2-cp310-cp310-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/xformers-0.0.33+c159edc0.d20250906-cp39-abi3-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/sageattention-2.2.0.post4-cp39-abi3-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl

uv pip install deepspeed

echo "Installing shared requirements..."

if [ -f ${WORKSPACE:-/workspace}/requirements.txt ]; then
    # Make sure venv is still activated
    source ComfyUI/venv/bin/activate
    uv pip install -r ${WORKSPACE:-/workspace}/requirements.txt
fi

# Install SwarmUI ExtraNodes
echo ""
echo "========================================================"
echo "SwarmUI ExtraNodes Installation"
echo "========================================================"
echo ""

cd ComfyUI

source venv/bin/activate

cd custom_nodes

# Remove existing SwarmComfyCommon if it exists
if [ -d "SwarmComfyCommon" ]; then
    echo "Removing existing SwarmComfyCommon..."
    rm -rf SwarmComfyCommon
fi

# Remove existing SwarmKSampler if it exists
if [ -d "SwarmKSampler" ]; then
    echo "Removing existing SwarmKSampler..."
    rm -rf SwarmKSampler
fi

echo "Downloading SwarmUI ExtraNodes (SwarmComfyCommon and SwarmKSampler)..."

# Clone SwarmUI with sparse checkout
git clone --depth 1 --filter=blob:none --sparse https://github.com/mcmonkeyprojects/SwarmUI
cd SwarmUI

# Checkout SwarmComfyCommon
echo "Downloading SwarmComfyCommon..."
git sparse-checkout set src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon
cp -r src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon ../SwarmComfyCommon

# Checkout SwarmKSampler
echo "Downloading SwarmKSampler..."
git sparse-checkout add src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmKSampler
cp -r src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmKSampler ../SwarmKSampler

cd ..

# Clean up temporary SwarmUI folder
rm -rf SwarmUI

echo "SwarmUI ExtraNodes installed successfully!"
echo ""
echo "Installed nodes:"
echo "  - SwarmComfyCommon"
echo "  - SwarmKSampler"
echo ""

cd ../..

echo "ComfyUI installation complete!"

