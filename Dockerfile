# Using megapak for more complete setup (includes more custom nodes)
FROM yanwk/comfyui-boot:cu128-megapak
# Alternative slim version: FROM yanwk/comfyui-boot:cu128-slim

# Set environment variables
ENV WORKSPACE=/workspace \
    HF_HOME=/root/.cache/huggingface/hub \
    PYTHONUNBUFFERED=1

# Install .NET 8 SDK for SwarmUI
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Install MinIO client (mc) and s3fs for S3 bucket mounting
# Base image is openSUSE Tumbleweed, so use zypper instead of apt-get
# Note: curl, fuse, and ca-certificates are already installed in the base image
RUN zypper refresh && \
    (zypper install -y --no-recommends wget s3fs psmisc || true) && \
    zypper clean

# Install MinIO client
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

# Set working directory
WORKDIR ${WORKSPACE}

# Copy installation scripts
COPY install-swarmui.sh ./

# Make scripts executable
RUN chmod +x install-swarmui.sh

# Install SwarmUI
RUN ./install-swarmui.sh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create directories for S3 mounts
RUN mkdir -p /mnt/s3-models /mnt/s3-hf-hub /mnt/s3-torch-hub /mnt/s3-input /mnt/s3-output /mnt/s3-workflows

# Expose ports
EXPOSE 7801 8188

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
