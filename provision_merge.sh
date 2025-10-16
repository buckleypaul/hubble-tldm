#!/usr/bin/env bash
# Device Provisioning Script for Hubble TLDM
# This script downloads necessary tools and firmware, then programs the device.

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
BASE_URL="https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master"
JLINK_TAR="jlink.tar.gz"
TAR_DIR="JLink_V862"
JLINK_EXE=""

# Key storage configuration
KEY_LENGTH=32         # Key length in bytes (256-bit key)

if [[ -z "$KEY_OFFSET" ]] || [[ -z "$UTC_OFFSET" ]]; then
    echo "[ERROR] KEY_OFFSET and UTC_OFFSET must be set" >&2
    exit 1
fi

# =============================================================================
# Command Line Argument Parsing
# =============================================================================
BOARD_ID=""
ORG_ID=""
BEARER_TOKEN=""
JLINK_DEVICE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --board-id)
            BOARD_ID="$2"
            shift 2
            ;;
        --org-id)
            ORG_ID="$2"
            shift 2
            ;;
        --bearer-token)
            BEARER_TOKEN="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --board-id <board>"
            echo "  --bearer-token API token (required)"
            echo "  --org-id       Organization ID (required)"
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
if [[ -z "$BOARD_ID" ]] || [[ -z "$ORG_ID" ]] || [[ -z "$BEARER_TOKEN" ]]; then
    echo "[ERROR] --board-id, --org-id, and --bearer-token are required" >&2
    echo "Usage: $0 --board-id <board> --org-id <org-id> --bearer-token <token>" >&2
    echo "Use --help for more information" >&2
    exit 1
fi

# Validate board ID
case "$BOARD_ID" in
    xg24_ek2703a)
        JLINK_DEVICE="EFR32MG24BxxxF1536"
        ;;
    nrf21540dk)
        JLINK_DEVICE="nRF52840_xxAA"
        ;;
    nrf52dk)
        JLINK_DEVICE="nRF52832_xxAA"
        ;;
    *)
        echo "[ERROR] Unsupported board ID: $BOARD_ID" >&2
        echo "[ERROR] Supported boards: xg24_ek2703a, nrf21540dk" >&2
        exit 1
        ;;
esac

# Set firmware filename based on board ID
echo "Firmware binary: $FIRMWARE_BIN"
if [ -n "${FIRMWARE_BIN+x}" ]; then
    echo "[INFO] Using set local binary $FIRMWARE_BIN"
else
    FIRMWARE_BIN="${BOARD_ID}.elf"
fi

MERGED_FIRMWARE_BIN="${BOARD_ID}_merged.elf"

echo "[INFO] Starting device provisioning..."

# Check if binary firmware is available
if [[ -f "$FIRMWARE_BIN" ]]; then
    echo "[INFO] Using binary firmware: $FIRMWARE_BIN"
    echo "[INFO] Output file: $MERGED_FIRMWARE_BIN"
else
    echo "[ERROR] Binary firmware file not found: $FIRMWARE_BIN" >&2
    exit 1
fi

# =============================================================================
# Register new device
# =============================================================================

API="https://api.hubble.com/api/v2/org/$ORG_ID/devices"

# Send the API request to get new device ID and key
resp_json="$(
  wget -qO- --content-on-error --no-check-certificate \
    --method POST \
    --timeout=0 \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer $BEARER_TOKEN" \
    --body-data '{
      "n_devices": 1,
      "encryption": "AES-256-CTR"
    }' \
    "$API"
)"

# Extract the device ID and key from the returned JSON
# devices is an array but we are only requesting a single device
DEVICE_ID=$(jq -r '.devices[0].device_id' <<<"$resp_json")
DEVICE_KEY=$(jq -r '.devices[0].key' <<<"$resp_json")

if [[ -n "$DEVICE_ID" && "$DEVICE_ID" != "null" ]]; then
  echo "[SUCCESS] Registered new device"
  echo "          Device ID:  $DEVICE_ID"
  echo "          Device Key: $DEVICE_KEY"
else
  echo "[ERROR] Failed to register device from backend" >&2
  echo "        Check that your organization ID and bearer token are valid" >&2
  echo "        Your token may be expired" >&2
  exit 1
fi

# =============================================================================
# Download and Extract JLink Tools
# =============================================================================
# Prefer system JLinkExe if present
SYSTEM_JLINK="$(command -v JLinkExe || true)"

if [[ -n "$SYSTEM_JLINK" ]]; then
    echo "[INFO] Using system JLinkExe at: $SYSTEM_JLINK"
    JLINK_EXE="$SYSTEM_JLINK"
else
    echo "[INFO] System JLinkExe not found; using bundled tools"

    if [[ -d "$TAR_DIR" ]]; then
        echo "[INFO] JLink tools already exist, skipping download"
    else
        echo "[INFO] Downloading JLink tools package..."
        if ! wget -q "$BASE_URL/$JLINK_TAR" -O "$JLINK_TAR"; then
            echo "[ERROR] Failed to download JLink tools" >&2
            exit 1
        fi

        if ! tar -xzf "$JLINK_TAR"; then
            echo "[ERROR] Failed to extract JLink tools" >&2
            exit 1
        fi
    fi

    JLINK_EXE="$TAR_DIR/JLinkExe"

    if [[ ! -f "$JLINK_EXE" ]]; then
        echo "[ERROR] JLink executable not found at $JLINK_EXE" >&2
        exit 1
    fi
    if [[ ! -x "$JLINK_EXE" ]]; then
        chmod +x "$JLINK_EXE"
    fi
    export PATH="$(pwd)/$TAR_DIR:$PATH"
fi

# =============================================================================
# Download Firmware Image
# =============================================================================
# Download binary firmware if it doesn't exist
if [[ ! -f "$FIRMWARE_BIN" ]]; then
    echo "[INFO] Downloading binary firmware for board: $BOARD_ID..."
    if ! wget -q "$BASE_URL/$FIRMWARE_BIN" -O "$FIRMWARE_BIN"; then
        echo "[ERROR] Failed to download binary firmware: $FIRMWARE_BIN" >&2
        echo "[ERROR] Make sure the binary firmware exists at: $BASE_URL/$FIRMWARE_BIN" >&2
        exit 1
    fi
    echo "[INFO] Binary firmware downloaded successfully"
fi

# Copy original file to output
cp "$FIRMWARE_BIN" "$MERGED_FIRMWARE_BIN"
echo "[SUCCESS] Created merged binary file: $MERGED_FIRMWARE_BIN"

# =============================================================================
# Merge Key into Firmware
# =============================================================================
echo "[INFO] Merging key into firmware at offset $KEY_OFFSET..."

# Convert offset to decimal
offset_decimal_key=$((KEY_OFFSET))

# Convert key to binary bytes
key_binary=$(printf '%s' "$DEVICE_KEY" | base64 -D)

# Get file size
file_size=$(stat -f%z "$FIRMWARE_BIN" 2>/dev/null || stat -c%s "$FIRMWARE_BIN" 2>/dev/null)

# Check if offset is within file bounds
if [[ $offset_decimal_key -ge $file_size ]]; then
    echo "[ERROR] Key offset $KEY_OFFSET is beyond file size $file_size" >&2
    exit 1
fi

# Check if key fits at offset
if [[ $((offset_decimal_key + KEY_LENGTH)) -gt $file_size ]]; then
    echo "[ERROR] Key would extend beyond file size" >&2
    exit 1
fi

# Write key to output file at specified offset
echo "[INFO] Writing key to binary file at offset $offset_decimal_key"
if ! printf "%s" "$key_binary" | dd of="$MERGED_FIRMWARE_BIN" bs=1 seek=$offset_decimal_key conv=notrunc 2>/dev/null; then
    echo "[ERROR] Failed to write key to binary file" >&2
    exit 1
fi

echo "[SUCCESS] Merged key into binary firmware"

# =============================================================================
# Merge UTC time into Firmware
# =============================================================================
echo "[INFO] Merging UTC time into firmware at offset $UTC_OFFSET..."

# Convert offset to decimal
offset_decimal_utc=$((UTC_OFFSET))

# Get the UTC time in milliseconds (approximately)
utc_time=$(($(date +%s)*1000))

# Check if UTC fits at offset
if [[ $((offset_decimal_utc + 8)) -gt $file_size ]]; then
    echo "[ERROR] UTC time would extend beyond file size" >&2
    exit 1
fi

# Write the UTC time to the output file after retrieving the current unix epoch. Reverse endianness.
if ! printf '%016x' "$utc_time" | \
    sed -E 's/(..)(..)(..)(..)(..)(..)(..)(..)/\8\7\6\5\4\3\2\1/' | \
    xxd -r -p | \
    dd of="$MERGED_FIRMWARE_BIN" bs=1 seek=$offset_decimal_utc conv=notrunc 2>/dev/null; then
    echo "[ERROR] Failed to write UTC to binary file" >&2
    exit 1
fi

echo "[SUCCESS] Merged UTC time into binary firmware"

# =============================================================================
# Flash Merged Firmware
# =============================================================================
echo "[INFO] Flashing merged firmware using JLinkExe..."

# Flash the merged binary firmware
echo "[INFO] Flashing merged binary firmware: $MERGED_FIRMWARE_BIN"

if ! printf "r\nloadfile $MERGED_FIRMWARE_BIN\nr\ng\nqc\n" | JLinkExe \
      -device "$JLINK_DEVICE" \
      -if SWD \
      -speed 4000 \
      -autoconnect 1; then
    echo "[ERROR] Firmware flashing failed" >&2
    exit 1
fi

echo "[SUCCESS] Device programmed successfully!"
echo "[INFO] Device ID: $DEVICE_ID has been provisioned with key at offset $KEY_OFFSET"
echo "[INFO] Merged binary firmware saved as: $MERGED_FIRMWARE_BIN"
