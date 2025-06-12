#!/bin/bash

DEVICE_ID=$1

# Detect connected board
if lsusb | grep -q "Nordic"; then
  BOARD="nrf52dk_nrf52832"
elif lsusb | grep -q "Espressif"; then
  BOARD="esp32"
elif lsusb | grep -q "Silicon Labs"; then
  BOARD="efr32mg24"
else
  echo "No supported dev board found"
  exit 1
fi

echo "Detected board: $BOARD"

# Request custom firmware build
FW_URL=$(curl -s -X POST http://localhost:8000/build_firmware \
  -H "Content-Type: application/json" \
  -d "{\"device_id\": \"$DEVICE_ID\", \"board\": \"$BOARD\"}" | jq -r .firmware_url)

if [[ -z "$FW_URL" || "$FW_URL" == "null" ]]; then
  echo "Failed to get firmware URL"
  exit 1
fi

echo "Downloading firmware from $FW_URL"
wget -q "$FW_URL" -O /tmp/custom_firmware.bin

# Flash firmware
if [[ "$BOARD" == "nrf52dk_nrf52832" ]]; then
  nrfjprog --program /tmp/custom_firmware.bin --chiperase --reset
elif [[ "$BOARD" == "esp32" ]]; then
  esptool.py --chip esp32 write_flash 0x1000 /tmp/custom_firmware.bin
elif [[ "$BOARD" == "efr32mg24" ]]; then
  commander flash /tmp/custom_firmware.bin
fi
