# MinIO S3 Bucket Setup

## Bucket Configuration

You need to create **two buckets** in MinIO:

### 1. `storage-models` Bucket
For model files and caches:
```
storage-models/
  ├── models/              # ComfyUI models (checkpoints, loras, vae, etc.)
  ├── hf-hub/           # HuggingFace cache
  └── torch-hub/        # PyTorch hub cache
```

### 2. `storage-user` Bucket
For user-generated content:
```
storage-user/
  ├── input/            # Input files
  ├── output/           # Generated outputs
  └── workflows/       # Workflow files
```

## Creating the Buckets in MinIO

1. Log into MinIO Console at `https://minio-api.v1su4.com`
2. Create bucket: **`storage-models`**
   - Create folder: `models/`
   - Create folder: `hf-hub/`
   - Create folder: `torch-hub/`
3. Create bucket: **`storage-user`**
   - Create folder: `input/`
   - Create folder: `output/`
   - Create folder: `workflows/`
4. Set bucket policies to allow read/write access for your access key

## Environment Variables

Add these to your `.env` file:

```bash
S3_ENDPOINT=https://minio-api.v1su4.com
S3_ACCESS_KEY=your_access_key_here
S3_SECRET_KEY=your_secret_key_here
S3_MODELS_BUCKET=storage-models
S3_USER_BUCKET=storage-user
S3_MODELS_PATH=models
```

## How It Works

The container mounts S3 buckets and creates symlinks:

- **storage-models/models/** → `/root/ComfyUI/models`
- **storage-models/hf-hub/** → `/root/.cache/huggingface/hub`
- **storage-models/torch-hub/** → `/root/.cache/torch/hub`
- **storage-user/input/** → `/root/ComfyUI/input`
- **storage-user/output/** → `/root/ComfyUI/output`
- **storage-user/workflows/** → `/root/ComfyUI/user/default/workflows`

## Models Folder Structure

The `models/` folder in `storage-models` bucket should follow ComfyUI's standard structure:

```
models/
├── checkpoints/          # Main model files (.safetensors, .ckpt)
├── loras/               # LoRA files
├── vae/                 # VAE models
├── clip/                # CLIP models
├── controlnet/          # ControlNet models
├── upscale_models/      # Upscaling models
├── embeddings/          # Textual inversions
└── ...
```

## Fallback Behavior

If S3 credentials are not provided, the container will use local storage volumes as fallback.
