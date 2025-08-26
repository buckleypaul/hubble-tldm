#!/bin/bash
set -e

# --- Parse command line arguments ---
DEVICE_ID=""
KEY=""

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
    *)
      echo "[WARNING] Unknown argument: $1"
      shift
      ;;
  esac
done

# --- Validate required arguments ---
if [ -z "$DEVICE_ID" ] || [ -z "$KEY" ]; then
  echo "[ERROR] --device-id and --key are required"
  echo "Usage: curl ... | bash -s -- --device-id <id> --key <key>"
  exit 1
fi

echo "[INFO] Provisioning device ID: $DEVICE_ID"

# --- Configuration ---
BASE_URL="http://localhost:8000"
JLINK_TAR="jlink.tar.gz"
FIRMWARE_HEX="zephyr.hex"
JLINK_URL="$BASE_URL/$JLINK_TAR"
FIRMWARE_URL="$BASE_URL/$FIRMWARE_HEX"
TAR_DIR="JLink_V862"
JLINK_EXE="$TAR_DIR/JLinkExe"
PYTHON_SCRIPT="provisioning_key.py"

# --- Download tools if not present ---
if [ -d "$TAR_DIR" ]; then
  echo "[INFO] Tools already exist, skipping download."
else
  echo "[INFO] Downloading JLink tools package..."
  wget -q "$JLINK_URL" -O "$JLINK_TAR"

  echo "[INFO] Extracting JLink tools..."
  tar -xzf "$JLINK_TAR"
fi

# --- Download firmware image if not present ---
if [ -f "$FIRMWARE_HEX" ]; then
  echo "[INFO] Firmware image already exists, skipping download."
else
  echo "[INFO] Downloading firmware image..."
  wget -q "$FIRMWARE_URL" -O "$FIRMWARE_HEX"
fi

# --- Flash firmware ---
chmod +x "$JLINK_EXE"

echo "[INFO] Flashing firmware using JLinkExe..."
printf "r\nloadfile zephyr.hex\nr\ng\nqc\n" | "$JLINK_EXE" -device EFR32MG24BxxxF1536 -if SWD -speed 4000 -autoconnect 1

# --- Run Python provisioning ---
echo "[INFO] Running Python provisioning with device ID and key..."
python3 "$PYTHON_SCRIPT" --id "$DEVICE_ID" --key "$KEY"

echo "[SUCCESS] Device programmed successfully."
