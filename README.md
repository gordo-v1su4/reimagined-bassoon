# SwarmUI + ComfyUI Docker Setup

Dockerized setup for SwarmUI and ComfyUI using the pre-built [ComfyUI Docker image](https://github.com/YanWenKun/ComfyUI-Docker) as base, with MinIO S3 integration for model storage.

## Features

- **Base Image**: Uses `yanwk/comfyui-boot:cu128-megapak` - pre-built, tested ComfyUI image
- **SwarmUI**: AI image and video generation interface
- **ComfyUI**: Node-based workflow system (from base image)
- **MinIO S3 Integration**: Models stored in S3 buckets
- **Dockerized**: Two separate services (ComfyUI and SwarmUI)
- **Coolify Ready**: Pre-configured for Coolify deployment
- ****

## Architecture

- **SwarmUI**: Port 7801 (.NET 8)
- **ComfyUI**: Port 8188 (from base image, Python 3.12, CUDA 12.8)
- **S3 Storage**: MinIO at `https://minio-api.v1su4.com`
- **Models Path**: S3 bucket `ai-models/models/` → `/root/ComfyUI/models`

## Prerequisites

- Docker and Docker Compose
- MinIO S3 credentials (access key and secret key)
- NVIDIA GPU with CUDA 12.8 support (for base image)

## Quick Start

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/gordo-v1su4/reimagined-bassoon.git
cd reimagined-bassoon
```

2. Create storage directories:
```bash
mkdir -p \
  storage \
  storage-models/models \
  storage-models/hf-hub \
  storage-models/torch-hub \
  storage-user/input \
  storage-user/output \
  storage-user/workflows
```

3. Set environment variables:
```bash
export HF_TOKEN=your_huggingface_token_here
export S3_ACCESS_KEY=your_minio_access_key
export S3_SECRET_KEY=your_minio_secret_key
export S3_ENDPOINT=https://minio-api.v1su4.com
export S3_BUCKET=ai-models
export S3_MODELS_PATH=ai-models/models
```

4. Build and run:
```bash
docker-compose build
docker-compose up -d
```

5. Access services:
- SwarmUI: http://localhost:7801
- ComfyUI: http://localhost:8188

### Coolify Deployment

1. Connect your GitHub repository to Coolify
2. Set environment variables in Coolify:
   - `HF_TOKEN`: Your HuggingFace token
   - `S3_ACCESS_KEY`: MinIO access key
   - `S3_SECRET_KEY`: MinIO secret key
   - `S3_ENDPOINT`: https://minio-api.v1su4.com
   - `S3_BUCKET`: ai-models
   - `S3_MODELS_PATH`: ai-models/models
3. Deploy using the docker-compose.yaml configuration

## Environment Variables

- `HF_TOKEN`: HuggingFace token for model downloads
- `HF_HOME`: HuggingFace cache directory (default: `/root/.cache/huggingface/hub`)
- `WORKSPACE`: Base workspace directory (default: `/workspace`)
- `S3_ENDPOINT`: MinIO S3 API endpoint (default: `https://minio-api.v1su4.com`)
- `S3_ACCESS_KEY`: MinIO access key (required for S3 mounting)
- `S3_SECRET_KEY`: MinIO secret key (required for S3 mounting)
- `S3_BUCKET`: S3 bucket name (default: `ai-models`)
- `S3_MODELS_PATH`: Path within bucket for models (default: `ai-models/models`)

## Volume Mounts

- `./storage`: General storage
- `./storage-models/models`: Local models (fallback if S3 not configured)
- `./storage-models/hf-hub`: HuggingFace cache
- `./storage-models/torch-hub`: PyTorch hub cache
- `./storage-user/input`: Input files
- `./storage-user/output`: Generated outputs
- `./storage-user/workflows`: Workflow files

## S3 Integration

The container automatically mounts the MinIO S3 bucket to `/mnt/s3-models` and creates a symlink from `/root/ComfyUI/models` to the S3 mount point.

**S3 Bucket Structure:**
```
ai-models/
  └── models/
      ├── checkpoints/
      ├── loras/
      ├── vae/
      └── ...
```

If S3 credentials are not provided, the container will use local storage as fallback.

## Custom Nodes

The base image (`yanwk/comfyui-boot:cu128-megapak`) includes ComfyUI-Manager and many pre-installed custom nodes. Additional nodes can be installed through ComfyUI-Manager's interface.

## Base Image

This setup uses `yanwk/comfyui-boot:cu128-megapak` as the base image, which provides:
- ComfyUI pre-installed
- ComfyUI-Manager
- Python 3.12
- CUDA 12.8 support
- PyTorch 2.8.0
- All necessary dependencies

See [ComfyUI-Docker](https://github.com/YanWenKun/ComfyUI-Docker) for more details.

## Troubleshooting

- **S3 mount fails**: Check S3 credentials and endpoint. Container will continue with local storage.
- **Port conflicts**: Modify port mappings in `docker-compose.yaml`
- **Check logs**: `docker-compose logs -f`
- **Restart services**: `docker-compose restart`

## License

See individual project licenses for SwarmUI and ComfyUI.
