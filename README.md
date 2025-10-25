# Hubble TLDM - Tool-Less Device Management

A streamlined device provisioning system for the **Hubble Terrestrial Network** that eliminates the need for manual tool installation and setup. TLDM (Tool-Less Device Management) automatically downloads all necessary tools, firmware, and dependencies, making device provisioning as simple as running a single command.

## Quick Start

Provision a device with a single command. Depending on the OS environment, this will download and install necessary tools.

Steps to run:
1. Plug in device via USB (*ensure this is not a power-only cable!*)
1. Open a terminal application
1. Get your organization ID and API access token from Hubble [here](https://dash.hubblenetwork.io/developer/api-tokens)
1. Paste the script below into the terminal, replacing ```<BOARD>``` ```<ORG_ID>``` and ```<API_TOKEN>``` with your values (see supported boards below)
1. Go!

### MacOS (Apple Silicon)
```bash
curl -s https://raw.githubusercontent.com/HubbleNetwork/hubble-tldm/refs/heads/master/run_macos.sh | bash -s -- <BOARD> <ORG_ID> <API_TOKEN>
```

This will install the following (if not previously installed):
* **[brew](https://brew.sh/)**: package manager necessary if Python is not installed
* **[python3](https://formulae.brew.sh/formula/python@3.14#default)**: the provisioning script uses this.
* **[pipx](https://formulae.brew.sh/formula/pipx)**: runs the python script in a virtual environment so it doesn't impact the rest of your installation
* **[segger-jlink](https://formulae.brew.sh/cask/segger-jlink#default)**: necessary for flashing devices

## Supported Boards

Currently supported boards:
* nrf52dk
* nrf52840dk
