#!/bin/bash
# Set up environment variables
export DISPLAY=:99
export XAUTHORITY=${DATA_DIR}/.Xauthority
export LD_LIBRARY_PATH=${DATA_DIR}/lib:$LD_LIBRARY_PATH
export PATH="${DATA_DIR}/python/python/bin:${PATH}"
export PATH="${DATA_DIR}/.local/bin:${PATH}"
export PYTHONPATH="${DATA_DIR}/pymodules:${PYTHONPATH}"
export PYTHONPATH="${DATA_DIR}/.local/lib/python3.11/site-packages:${PYTHONPATH}"

echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W}" ]; then
    CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H}" ]; then
    CUSTOM_RES_H=768
fi
if [ "${CUSTOM_RES_W}" -le 1023 ]; then
    echo "---Width too low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
    echo "---Height too low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi

echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;

echo "---Checking for old display lock files---"
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid ${DATA_DIR}/Singleton*

chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
    chmod 600 ${DATA_DIR}/.vnc/passwd
fi

screen -wipe 2&>/dev/null

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :99 -rfbport ${RFB_PORT} -noxstartup ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2

echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2

echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}


echo "---Starting REAL-Video-Enhancer---"
cd ${DATA_DIR}
EXECUTABLE=$(find ${DATA_DIR}/bin -type f -executable -print | grep -i "REAL-Video-Enhancer")
if [ -z "$EXECUTABLE" ]; then
    echo "Error: Could not find REAL-Video-Enhancer executable"
    echo "Contents of ${DATA_DIR}/bin:"
    ls -R ${DATA_DIR}/bin
    exit 1
fi

# Function to check if a package is installed
is_installed() {
    ${DATA_DIR}/python/python/bin/python3 -m pip list 2>/dev/null | grep -q "^$1 "
}

# Function to check if any pip install process is running
is_pip_running() {
    pgrep -f "pip install" > /dev/null
}

# Function to display a message in a window and wait for it to close
display_message() {
    zenity --info --text="$1" --title="REAL-Video-Enhancer" --width=300 --height=100 &
    ZENITY_PID=$!
    # Wait for the zenity process to finish
    wait $ZENITY_PID
}

# Function to display a progress bar
display_progress() {
    (
    echo "0"
    echo "# Installing nvidia-modelopt. Please wait..."
    ${DATA_DIR}/python/python/bin/python3 -m pip install "nvidia-modelopt[all]~=0.19.0" --extra-index-url https://pypi.nvidia.com
    echo "100"
    echo "# Installation complete. Restarting in 10 seconds..."
    sleep 10
    ) |
    zenity --progress \
      --title="REAL-Video-Enhancer" \
      --text="Installing nvidia-modelopt..." \
      --percentage=0 \
      --auto-close \
      --width=300 \
      --height=100
}

# Function to check and install nvidia-modelopt
check_and_install_modelopt() {
    if [ -f "${DATA_DIR}/python/python/bin/python3" ]; then
        if is_installed "torch" || is_installed "tensorrt" || is_installed "onnx"; then
            if ! is_installed "nvidia-modelopt"; then
                display_message "IMPORTANT: nvidia-modelopt needs to be installed.\nThe installation will start now."
                display_progress
                return 0
            fi
        fi
    fi
    return 1
}

# Function to monitor and install nvidia-modelopt
monitor_and_install() {
    while true; do
        if ! is_pip_running; then
            if check_and_install_modelopt; then
                kill -TERM $1  # Send termination signal to REAL-Video-Enhancer
                return 0
            fi
        fi
        sleep 30  # Check every 30 seconds
    done
}

while true; do
    echo "Starting $EXECUTABLE"

    # Check if NO_FULLSCREEN is set (to any value)
    if [ -z "$NO_FULLSCREEN" ]; then
        FLAGS="--fullscreen"
    else
        FLAGS=""
    fi

    # Start the executable with or without the fullscreen flag
    $EXECUTABLE $FLAGS &
    PID=$!
    
    # Start monitoring in background
    monitor_and_install $PID &
    MONITOR_PID=$!
    
    # Wait for the process to finish
    wait $PID
    
    # Kill the monitoring process if it's still running
    kill $MONITOR_PID 2>/dev/null
    
    display_message "REAL-Video-Enhancer has stopped. Restarting in 5 seconds..."
    sleep 5
done
