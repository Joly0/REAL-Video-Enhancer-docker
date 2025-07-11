# Stage 1: Python base image for opencv and tqdm modules
FROM python:3.11 AS builder
# Install pip for Python 3.11 and required Python packages (numpy, opencv, tqdm, etc.)
RUN python3 -m pip install --no-warn-script-location numpy
RUN python3 -m pip install --user --no-warn-script-location opencv-python tqdm

# Stage 2: Download and extract REAL-Video-Enhancer
FROM ubuntu:20.04 AS downloader
RUN apt-get update && apt-get install -y curl unzip
WORKDIR /tmp
RUN DOWNLOAD_URL=$(curl -s https://api.github.com/repos/TNTwise/REAL-Video-Enhancer/releases/latest | grep -i 'browser_download_url' | grep -i 'linux' | grep -i 'x86_64' | cut -d '"' -f 4) && \
    curl -L "$DOWNLOAD_URL" -o REAL-Video-Enhancer-Linux.zip && \
    unzip REAL-Video-Enhancer-Linux.zip && \
    rm REAL-Video-Enhancer-Linux.zip

# Stage 3: Final Image
FROM ich777/novnc-baseimage
# Basic environment setups
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DATA_DIR=/app
ENV CUSTOM_RES_W=1920
ENV CUSTOM_RES_H=1080
ENV CUSTOM_DEPTH=24
ENV NOVNC_PORT=6080
ENV RFB_PORT=5900
ENV TURBOVNC_PARAMS="-securitytypes none"
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="realvideoenhancer"
ENV QT_LOGGING_RULES="*.debug=false;qt.*.debug=false"

# Install basic system dependencies (no Python!)
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libxcb-xinerama0 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libegl1 \
    libopengl0 \
    libglx0 \
    libglu1-mesa \
    libxcb-cursor0 \
    libxcb1 \
    libx11-xcb1 \
    libxcb-glx0 \
    libxcb-util1 \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libqt5gui5 \
    libqt5core5a \
    libqt5dbus5 \
    libqt5network5 \
    libqt5widgets5 \
    pciutils \
    zenity \
    && rm -rf /var/lib/apt/lists/*

# Set up the user
RUN useradd -d ${DATA_DIR} -s /bin/bash ${USER} && \
    mkdir -p ${DATA_DIR} /data /config && \
    chown -R ${USER}:${USER} ${DATA_DIR} /data /config && \
    ln -s /config/settings.txt /app/settings.txt

WORKDIR ${DATA_DIR}

# Copy Python packages from builder stage
COPY --from=builder /root/.local ${DATA_DIR}/.local

# Copy REAL-Video-Enhancer bin folder from downloader stage
COPY --from=downloader /tmp/bin ${DATA_DIR}/bin

# Setup scripts
COPY scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

# Copy Fluxbox config file
COPY /conf/ /etc/.fluxbox/

# Expose noVNC port
EXPOSE 6080

# Final entry point
ENTRYPOINT ["/opt/scripts/start.sh"]
