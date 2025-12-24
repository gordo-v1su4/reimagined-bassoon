# Build Instructions

## Building on the Server

Since the files are on your server at `~/swarmui` (mounted as Z:\swarmui on Windows), you can build the Docker image directly on the server.

### Option 1: Using SSH

```bash
ssh gordo@v1su4.com
cd ~/swarmui
chmod +x build.sh
./build.sh
```

### Option 2: Using Docker Compose

```bash
ssh gordo@v1su4.com
cd ~/swarmui
docker-compose build
```

### Option 3: Direct Docker Build

```bash
ssh gordo@v1su4.com
cd ~/swarmui
docker build -t swarmui-comfyui:latest .
```

## Common Build Issues and Fixes

### Issue: Python version not found
**Fix**: The Dockerfile sets up Python 3.11 and creates a symlink. If issues persist, check that `python3.11` is installed.

### Issue: Venv not activated
**Fix**: All scripts now properly source the venv before using Python/pip commands.

### Issue: UV not found
**Fix**: UV is installed in the venv after it's created. Make sure the venv is activated.

### Issue: Path errors
**Fix**: All scripts now use `${WORKSPACE:-/workspace}` for consistent paths.

## Testing the Build

After building, test with:

```bash
docker run --rm -it swarmui-comfyui:latest /bin/bash
```

Or run with docker-compose:

```bash
docker-compose up
```

## Monitoring Build Progress

The build will take a while (30-60 minutes) as it:
1. Installs system dependencies
2. Installs .NET 8 SDK
3. Clones and installs ComfyUI
4. Installs all custom nodes
5. Installs SwarmUI
6. Downloads and installs .whl files

Watch for any errors and they will be reported in the build output.

