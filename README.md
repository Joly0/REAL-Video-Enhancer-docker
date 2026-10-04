# REAL-Video-Enhancer-docker

[REAL Video Enhancer](https://github.com/TNTwise/REAL-Video-Enhancer) in a container, accessible from any web browser.

REAL Video Enhancer interpolates, upscales, decompresses and denoises videos with AI models such as RIFE for frame interpolation, using NCNN, PyTorch (CUDA) or TensorRT backends. This image runs the desktop app on a small Linux desktop that is streamed to your browser through noVNC, so you can run it on a server with a GPU (Unraid, a home lab box) and use it from any device on your network.

[![Release build](https://github.com/Joly0/REAL-Video-Enhancer-docker/actions/workflows/latest_release.yml/badge.svg)](https://github.com/Joly0/REAL-Video-Enhancer-docker/actions/workflows/latest_release.yml)
[![License](https://img.shields.io/github/license/Joly0/REAL-Video-Enhancer-docker)](LICENSE)

## Features

- **REAL Video Enhancer in the browser**: the app runs full screen on a TurboVNC desktop, streamed through noVNC on port `6080`
- **Release, pre-release and development builds**: new upstream versions are picked up automatically, see [image tags](#image-tags)
- **NVIDIA GPU support**: use the CUDA and TensorRT backends with `--gpus all`; the `nvidia-modelopt` package they need is installed automatically
- **Persistent backends and models**: map the backend Python environment and model folders to keep downloads across container updates
- **Self-healing**: the app is restarted automatically if it crashes or is closed
- **Unraid friendly**: runs as UID `99` / GID `100` by default, with a configurable umask

## Quick start

### docker run

```bash
docker run -d \
  --name=real-video-enhancer \
  --gpus all \
  --shm-size=2g \
  -p 6080:6080 \
  -e UID=99 \
  -e GID=100 \
  -v /path/to/config:/config \
  -v /path/to/python:/app/python/python \
  -v /path/to/models:/app/models \
  -v /path/to/custom_models:/app/custom_models \
  -v /path/to/import:/app/import \
  -v /path/to/output:/app/Videos \
  --restart unless-stopped \
  ghcr.io/joly0/real-video-enhancer-docker:latest
```

### docker compose

```yaml
services:
  real-video-enhancer:
    image: ghcr.io/joly0/real-video-enhancer-docker:latest
    container_name: real-video-enhancer
    environment:
      - UID=99
      - GID=100
    volumes:
      - /path/to/config:/config
      - /path/to/python:/app/python/python
      - /path/to/models:/app/models
      - /path/to/custom_models:/app/custom_models
      - /path/to/import:/app/import
      - /path/to/output:/app/Videos
    ports:
      - 6080:6080
    shm_size: "2gb"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped
```

Then open **http://yourhost:6080/** in your browser.

On first start, install a backend from the app's settings. The CUDA and TensorRT backends need an NVIDIA GPU and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host (on Unraid, the Nvidia Driver plugin). Once one of them is installed, the container installs `nvidia-modelopt` and restarts the app; a message window shows the progress.

> [!WARNING]
> The noVNC desktop has no password. Anyone who can reach port `6080` can use the app and see the mapped folders, so keep it on a trusted network or behind a reverse proxy with authentication.

## Parameters

### Ports

| Port | Description |
| --- | --- |
| `6080` | noVNC web interface |

### Volumes

| Path | Description |
| --- | --- |
| `/config` | App settings (`settings.txt`) |
| `/app/python/python` | Python environment of the installed backends; map it so backends are not downloaded again after every update |
| `/app/models` | Downloaded models |
| `/app/custom_models` | Your own models |
| `/app/import` | Videos to enhance; any folder works, this is just a suggestion |
| `/app/Videos` | Output folder for rendered videos |

### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `UID` | `99` | User ID the app runs as |
| `GID` | `100` | Group ID the app runs as |
| `UMASK` | `000` | Umask for files the app creates |
| `DATA_PERM` | `770` | Permissions applied to `/app` on start |
| `CUSTOM_RES_W` | `1920` | Width of the virtual desktop in pixels (minimum `1024`) |
| `CUSTOM_RES_H` | `1080` | Height of the virtual desktop in pixels (minimum `768`) |
| `NO_FULLSCREEN` | | Set to any value to start the app in a normal window instead of full screen |

### Extra run options

| Option | Description |
| --- | --- |
| `--gpus all` | Passes NVIDIA GPUs into the container; needed for the CUDA and TensorRT backends |
| `--shm-size=2g` | More shared memory for PyTorch and video processing |
| `-v /path/to/user.sh:/opt/custom/user.sh` | Optional script run as root on every start, before the app, e.g. to install extra packages |

## Image tags

Images are published to the [GitHub Container Registry](https://github.com/Joly0/REAL-Video-Enhancer-docker/pkgs/container/real-video-enhancer-docker) as `ghcr.io/joly0/real-video-enhancer-docker`.

| Tag | Built from | Checked for updates |
| --- | --- | --- |
| `latest` | Newest stable [release](https://github.com/TNTwise/REAL-Video-Enhancer/releases) | daily |
| `pre-release` | Newest pre-release | every 2 hours |
| `dev` | Upstream `main` branch, built from source | every 2 hours |

Only `linux/amd64` is built. A new image is only pushed when upstream has changed since the last build.

## Building locally

```bash
git clone https://github.com/Joly0/REAL-Video-Enhancer-docker.git
cd REAL-Video-Enhancer-docker
docker build -t real-video-enhancer -f dockerfile .
```

Use `-f dockerfile.pre` for the newest pre-release or `-f dockerfile.dev` to build the upstream `main` branch from source.

## Support

Problems with the container go to the [issue tracker](https://github.com/Joly0/REAL-Video-Enhancer-docker/issues). Problems with REAL Video Enhancer itself (models, rendering, backends) belong in the [upstream repository](https://github.com/TNTwise/REAL-Video-Enhancer/issues).

## Credits and license

[REAL Video Enhancer](https://github.com/TNTwise/REAL-Video-Enhancer) is developed by TNTwise. The desktop streaming is based on [ich777's noVNC base image](https://github.com/ich777/docker-novnc-baseimage).

This repository is licensed under [GPL-3.0](LICENSE).
