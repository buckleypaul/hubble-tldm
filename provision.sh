#!/bin/bash
# Device Provisioning Script for Hubble TLDM
# This script downloads necessary tools and firmware, then programs the device.

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
BASE_URL="https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master"
JLINK_TAR="jlink.tar.gz"
PYTHON_SCRIPT="provision_key.py"
TAR_DIR="JLink_V862"
JLINK_EXE="$TAR_DIR/JLinkExe"

# =============================================================================
# Command Line Argument Parsing
# =============================================================================
DEVICE_ID=""
KEY=""
BOARD_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --device-id)
            DEVICE_ID="$2"
            shift 2
            ;;
        --key)
            KEY="$2"
            shift 2
            ;;
        --board-id)
            BOARD_ID="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --device-id <id> --key <key> --board-id <board>"
            echo "  --device-id    Device identifier (required)"
            echo "  --key          Device key (required)"
            echo "  --board-id     Board identifier (required, e.g., efr32mg24-dk)"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            echo "[WARNING] Unknown argument: $1" >&2
            echo "Use --help for usage information" >&2
            shift
            ;;
    esac
done

# =============================================================================
# Validation
# =============================================================================
if [[ -z "$DEVICE_ID" ]] || [[ -z "$KEY" ]] || [[ -z "$BOARD_ID" ]]; then
    echo "[ERROR] --device-id, --key, and --board-id are required" >&2
    echo "Usage: $0 --device-id <id> --key <key> --board-id <board>" >&2
    echo "Use --help for more information" >&2
    exit 1
fi

# Set firmware filename based on board ID
FIRMWARE_HEX="${BOARD_ID}.hex"

echo "[INFO] Starting device provisioning..."
echo "[INFO] Device ID: $DEVICE_ID"
echo "[INFO] Board ID: $BOARD_ID"
echo "[INFO] Firmware: $FIRMWARE_HEX"

# =============================================================================
# Download and Extract JLink Tools
# =============================================================================
if [[ -d "$TAR_DIR" ]]; then
    echo "[INFO] JLink tools already exist, skipping download"
else
    echo "[INFO] Downloading JLink tools package..."
    if ! wget -q "$BASE_URL/$JLINK_TAR" -O "$JLINK_TAR"; then
        echo "[ERROR] Failed to download JLink tools" >&2
        exit 1
    fi

    echo "[INFO] Extracting JLink tools..."
    if ! tar -xzf "$JLINK_TAR"; then
        echo "[ERROR] Failed to extract JLink tools" >&2
        exit 1
    fi
fi

# =============================================================================
# Download Firmware Image
# =============================================================================
if [[ -f "$FIRMWARE_HEX" ]]; then
    echo "[INFO] Firmware image already exists, skipping download"
else
    echo "[INFO] Downloading firmware image for board: $BOARD_ID..."
    if ! wget -q "$BASE_URL/$FIRMWARE_HEX" -O "$FIRMWARE_HEX"; then
        echo "[ERROR] Failed to download firmware image: $FIRMWARE_HEX" >&2
        echo "[ERROR] Make sure the firmware file exists at: $BASE_URL/$FIRMWARE_HEX" >&2
        exit 1
    fi
fi

# =============================================================================
# Flash Firmware
# =============================================================================
if [[ ! -f "$JLINK_EXE" ]]; then
    echo "[ERROR] JLink executable not found at $JLINK_EXE" >&2
    exit 1
fi

chmod +x "$JLINK_EXE"

echo "[INFO] Flashing firmware using JLinkExe..."
if ! printf "r\nloadfile $FIRMWARE_HEX\nr\ng\nqc\n" | "$JLINK_EXE" \
    -device EFR32MG24BxxxF1536 \
    -if SWD \
    -speed 4000 \
    -autoconnect 1; then
    echo "[ERROR] Firmware flashing failed" >&2
    exit 1
fi

# =============================================================================
# Serial Port Detection
# =============================================================================
echo "[INFO] Serial port detection starting..."
echo "[INFO] Please unplug your device and press Enter when ready..."
read -r

# Get list of current TTY devices
echo "[INFO] Scanning for current TTY devices..."
current_ttys=$(ls /dev/tty* 2>/dev/null | sort)

echo "[INFO] Now please plug in your device and press Enter..."
read -r

# Wait a moment for device to be recognized
sleep 2

# Get list of TTY devices after plugging in
echo "[INFO] Scanning for new TTY devices..."
new_ttys=$(ls /dev/tty* 2>/dev/null | sort)

# Find the new device
new_device=""
for tty in $new_ttys; do
    if ! echo "$current_ttys" | grep -q "^$tty$"; then
        new_device="$tty"
        break
    fi
done

if [[ -z "$new_device" ]]; then
    echo "[ERROR] No new TTY device detected" >&2
    echo "[INFO] Available TTY devices:" >&2
    echo "$new_ttys" >&2
    exit 1
fi

echo "[SUCCESS] Detected new TTY device: $new_device"
SERIAL_PORT="$new_device"

# =============================================================================
# Run Python Provisioning
# =============================================================================
echo "[INFO] Running Python provisioning with device ID and key..."
echo "[INFO] Using serial port: $SERIAL_PORT"
if ! python3 "$PYTHON_SCRIPT" --base64 "$KEY" "$SERIAL_PORT"; then
    echo "[ERROR] Python provisioning failed" >&2
    exit 1
fi

echo "[SUCCESS] Device programmed successfully!"
echo "[INFO] Device ID: $DEVICE_ID has been provisioned"
