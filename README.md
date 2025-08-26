# Hubble TLDM - Tool-Less Device Management

A streamlined device provisioning system that eliminates the need for manual tool installation and setup. TLDM (Tool-Less Device Management) automatically downloads all necessary tools, firmware, and dependencies, making device provisioning as simple as running a single command.

## What is Tool-Less Device Management?

**Tool-Less Device Management (TLDM)** means you don't need to:
- Manually install JLink tools
- Download firmware images
- Set up Python environments
- Configure serial ports
- Install dependencies

Everything is automatically downloaded and configured during the provisioning process.

## Quick Start

Provision a device with a single command - no tools to install first:

```bash
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/provision.sh | bash -s -- --device-id 214cca30-ca6f-48c2-8d7c-55368276471c --key OTQhLHNU385buqYhthomsmwvd+sGRqoE5QIAXcBGg= --board-id efr32mg24-dk
```

## The Tool-Less Advantage

### Traditional Approach (Tool-Heavy)
1. Download and install JLink tools manually
2. Download firmware images separately
3. Set up Python environment
4. Install serial communication libraries
5. Configure device connections
6. Run provisioning scripts

### TLDM Approach (Tool-Less)
1. Run one command
2. Everything else happens automatically

## What This Does

The provisioning script automatically:

1. **Downloads JLink tools** - Professional debugging and programming tools
2. **Downloads firmware** - Board-specific firmware image (e.g., `efr32mg24-dk.hex`)
3. **Sets up Python environment** - Creates virtual environment and installs dependencies
4. **Flashes firmware** - Programs the device with the specified firmware
5. **Detects serial port** - Automatically finds USB modem devices
6. **Provisions device key** - Securely transfers cryptographic keys to the device

## Requirements

- **Python 3.x** (tested with Python 3.9.6) - Only requirement that needs to be pre-installed
- **System tools**: `wget`, `curl`, `tar`, `python3`, `pip` - Usually available by default
- **Hardware**: JLink-compatible device connected via USB

## Usage

### Basic Provisioning

```bash
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/provision.sh | bash -s -- --device-id <device-id> --key <key> --board-id <board-name>
```

### Parameters

- **`--device-id`**: Unique identifier for the device (UUID format)
- **`--key`**: Cryptographic key for the device (base64 encoded)
- **`--board-id`**: Board identifier (e.g., `efr32mg24-dk`, `nrf52840-dk`)

### Examples

```bash
# EFR32MG24 Development Kit
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/provision.sh | bash -s -- --device-id 214cca30-ca6f-48c2-8d7c-55368276471c --key OTQhLHNU385buqYhthomsmwvd+sGRqoE5QIAXcBGg= --board-id efr32mg24-dk

# Nordic nRF52840 Development Kit
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/provision.sh | bash -s -- --device-id 12345678-1234-1234-1234-123456789abc --key <your-base64-key> --board-id nrf52840-dk

# STM32F4 Discovery
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/provision.sh | bash -s -- --device-id 87654321-4321-4321-4321-cba987654321 --key <your-base64-key> --board-id stm32f4-discovery
```

## How Tool-Less Management Works

### 1. Automatic Tool Downloads
The script downloads all necessary components from GitHub:
- **JLink tools**: Professional debugging suite (no manual installation)
- **Firmware images**: Board-specific `.hex` files (no manual download)
- **Python scripts**: Provisioning and key management (no manual setup)
- **Dependencies**: Python package requirements (no manual pip install)

### 2. Zero-Configuration Environment Setup
- Creates Python virtual environment (`.venv`) automatically
- Installs required packages (`pyserial` for serial communication)
- Downloads and extracts JLink tools
- No configuration files or manual setup required

### 3. Intelligent Device Programming
- Flashes firmware using automatically downloaded JLinkExe
- Supports various device types (EFR32, nRF52, STM32, etc.)
- Configurable connection parameters (SWD, speed, etc.)
- No manual JLink configuration needed

### 4. Smart Serial Communication
- Automatically detects USB modem devices (`/dev/tty.usbmodem*`)
- Establishes serial connection for key provisioning
- Handles base64-encoded cryptographic keys
- No manual port configuration required

## Supported Boards

The system supports any board that:
- Has JLink-compatible debugging interface
- Supports SWD programming
- Has a firmware image named `{board-id}.hex`

Common examples:
- **Silicon Labs**: EFR32MG24-DK, EFR32FG14-DK
- **Nordic**: nRF52840-DK, nRF52833-DK
- **STMicroelectronics**: STM32F4-Discovery, STM32L4-Discovery
- **Custom boards**: Any board with compatible debugging interface

## File Structure
