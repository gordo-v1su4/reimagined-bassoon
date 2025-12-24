#!/bin/bash

# Don't exit on errors - we want to continue even if S3 mounting fails
set +e

COMFYUI_DIR="/root/ComfyUI"

# Install s3fs if not already installed (base image might not have it)
if ! command -v s3fs &> /dev/null; then
    echo "Installing s3fs..."
    zypper refresh -q && \
    zypper install -y --no-recommends s3fs fuse psmisc 2>/dev/null || \
    (echo "Warning: Failed to install s3fs. S3 mounting will be skipped." && true)
fi

# MinIO S3 Configuration
S3_ENDPOINT="${S3_ENDPOINT:-https://minio-api.v1su4.com}"
S3_ACCESS_KEY="${S3_ACCESS_KEY}"
S3_SECRET_KEY="${S3_SECRET_KEY}"
S3_MODELS_BUCKET="${S3_MODELS_BUCKET:-storage-models}"
S3_USER_BUCKET="${S3_USER_BUCKET:-storage-user}"
S3_MODELS_PATH="${S3_MODELS_PATH:-models}"

# Function to mount S3 bucket using s3fs
mount_s3() {
    local mount_point=$1
    local s3_bucket_path=$2  # Format: bucket:path or just path (uses default bucket)
    
    if [ -z "$S3_ACCESS_KEY" ] || [ -z "$S3_SECRET_KEY" ]; then
        echo "Warning: S3 credentials not provided. Skipping S3 mount for $mount_point"
        return 1
    fi
    
    # Extract bucket name and path
    local bucket_name
    local s3_path
    if [[ "$s3_bucket_path" == *":"* ]]; then
        # Format: bucket:path
        bucket_name="${s3_bucket_path%%:*}"
        s3_path="${s3_bucket_path#*:}"
    else
        # Just path provided, use default models bucket
        bucket_name="${S3_MODELS_BUCKET}"
        s3_path="$s3_bucket_path"
    fi
    
    echo "Mounting S3 bucket: ${bucket_name}:${s3_path} to $mount_point"
    
    # Create mount point if it doesn't exist
    mkdir -p "$mount_point"
    
    # Create credentials file for s3fs
    echo "${S3_ACCESS_KEY}:${S3_SECRET_KEY}" > /tmp/.s3fs-credentials
    chmod 600 /tmp/.s3fs-credentials
    
    # Mount S3 bucket using s3fs
    # Format: s3fs bucket-name:path mount-point -o url=endpoint,use_path_request_style
    s3fs "${bucket_name}:${s3_path}" "$mount_point" \
        -o url="${S3_ENDPOINT}" \
        -o use_path_request_style \
        -o allow_other \
        -o passwd_file=/tmp/.s3fs-credentials \
        -o use_cache=/tmp/s3fs-cache \
        -o ensure_diskfree=1000 \
        -o retries=5 \
        -o multipart_size=128 \
        -o parallel_count=5 \
        -o multireq_max=5 \
        -o max_stat_cache_size=100000 \
        -o stat_cache_expire=900 \
        -o enable_noobj_cache \
        -o no_time_stamp_msg || {
        echo "Warning: Failed to mount S3 bucket. Continuing without S3 mount."
        rm -f /tmp/.s3fs-credentials
        return 1
    }
    
    rm -f /tmp/.s3fs-credentials
    
    echo "S3 bucket mounted successfully at $mount_point"
    return 0
}

# Function to handle shutdown
cleanup() {
    echo ""
    echo "Shutting down ComfyUI..."
    
    # Unmount S3 buckets
    umount /mnt/s3-models 2>/dev/null || true
    umount /mnt/s3-hf-hub 2>/dev/null || true
    umount /mnt/s3-torch-hub 2>/dev/null || true
    umount /mnt/s3-input 2>/dev/null || true
    umount /mnt/s3-output 2>/dev/null || true
    umount /mnt/s3-workflows 2>/dev/null || true
    
    # Kill ComfyUI if running
    if [ ! -z "$COMFYUI_PID" ]; then
        echo "Stopping ComfyUI (PID: $COMFYUI_PID)..."
        kill $COMFYUI_PID 2>/dev/null || true
        wait $COMFYUI_PID 2>/dev/null || true
    fi
    
    # Kill any processes on port 8188
    fuser -k 8188/tcp 2>/dev/null || true
    
    echo "ComfyUI stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Mount S3 buckets if credentials are provided
if [ ! -z "$S3_ACCESS_KEY" ] && [ ! -z "$S3_SECRET_KEY" ]; then
    echo "Setting up S3 mounts..."
    
    # Mount models directory from storage-models bucket
    mount_s3 /mnt/s3-models "${S3_MODELS_BUCKET}:${S3_MODELS_PATH}" || true
    
    # Mount HuggingFace hub cache from storage-models bucket
    mount_s3 /mnt/s3-hf-hub "${S3_MODELS_BUCKET}:hf-hub" || true
    
    # Mount PyTorch hub cache from storage-models bucket
    mount_s3 /mnt/s3-torch-hub "${S3_MODELS_BUCKET}:torch-hub" || true
    
    # Mount user directories from storage-user bucket
    mount_s3 /mnt/s3-input "${S3_USER_BUCKET}:input" || true
    mount_s3 /mnt/s3-output "${S3_USER_BUCKET}:output" || true
    mount_s3 /mnt/s3-workflows "${S3_USER_BUCKET}:workflows" || true
    
    # Create symlinks to S3 mounts in ComfyUI directory
    if [ -d "/mnt/s3-models" ] && mountpoint -q /mnt/s3-models 2>/dev/null; then
        echo "Linking S3 models to ComfyUI models directory..."
        # Backup existing models if they exist and it's not already a symlink
        if [ -d "${COMFYUI_DIR}/models" ] && [ ! -L "${COMFYUI_DIR}/models" ]; then
            if [ ! -d "${COMFYUI_DIR}/models.local" ]; then
                mv "${COMFYUI_DIR}/models" "${COMFYUI_DIR}/models.local" || true
            fi
        fi
        # Remove existing symlink if it exists
        rm -f "${COMFYUI_DIR}/models"
        # Create symlink to S3 models
        ln -s /mnt/s3-models "${COMFYUI_DIR}/models" || true
        echo "S3 models linked to ${COMFYUI_DIR}/models"
    fi
    
    # Link HuggingFace cache if mounted
    if [ -d "/mnt/s3-hf-hub" ] && mountpoint -q /mnt/s3-hf-hub 2>/dev/null; then
        echo "Linking S3 HuggingFace cache..."
        mkdir -p /root/.cache/huggingface
        rm -rf /root/.cache/huggingface/hub
        ln -s /mnt/s3-hf-hub /root/.cache/huggingface/hub || true
    fi
    
    # Link PyTorch hub cache if mounted
    if [ -d "/mnt/s3-torch-hub" ] && mountpoint -q /mnt/s3-torch-hub 2>/dev/null; then
        echo "Linking S3 PyTorch hub cache..."
        mkdir -p /root/.cache/torch
        rm -rf /root/.cache/torch/hub
        ln -s /mnt/s3-torch-hub /root/.cache/torch/hub || true
    fi
    
    # Link user directories if mounted
    if [ -d "/mnt/s3-input" ] && mountpoint -q /mnt/s3-input 2>/dev/null; then
        echo "Linking S3 input directory..."
        rm -rf "${COMFYUI_DIR}/input"
        ln -s /mnt/s3-input "${COMFYUI_DIR}/input" || true
    fi
    
    if [ -d "/mnt/s3-output" ] && mountpoint -q /mnt/s3-output 2>/dev/null; then
        echo "Linking S3 output directory..."
        rm -rf "${COMFYUI_DIR}/output"
        ln -s /mnt/s3-output "${COMFYUI_DIR}/output" || true
    fi
    
    if [ -d "/mnt/s3-workflows" ] && mountpoint -q /mnt/s3-workflows 2>/dev/null; then
        echo "Linking S3 workflows directory..."
        mkdir -p "${COMFYUI_DIR}/user/default"
        rm -rf "${COMFYUI_DIR}/user/default/workflows"
        ln -s /mnt/s3-workflows "${COMFYUI_DIR}/user/default/workflows" || true
    fi
else
    echo "S3 credentials not provided. Using local storage."
fi

# Start ComfyUI using the base image's entrypoint script
echo "Starting ComfyUI using base image entrypoint..."
if [ -f "/runner-scripts/entrypoint.sh" ]; then
    # Use the base image's entrypoint which handles ComfyUI startup
    exec /runner-scripts/entrypoint.sh
else
    # Fallback: try to start ComfyUI manually
    echo "Warning: Base image entrypoint not found, trying manual startup..."
    COMFYUI_DIR="/root/ComfyUI"
    if [ ! -d "${COMFYUI_DIR}" ]; then
        # Try to find ComfyUI
        COMFYUI_DIR=$(find /root /workspace -type d -name "ComfyUI" 2>/dev/null | head -1)
        if [ -z "$COMFYUI_DIR" ]; then
            echo "Error: ComfyUI directory not found"
            exit 1
        fi
    fi
    
    cd "${COMFYUI_DIR}"
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    exec python3 main.py --listen 0.0.0.0 --port 8188
fi

