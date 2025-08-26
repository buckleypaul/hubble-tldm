# Hubble TLDM

A device management API service for provisioning and managing IoT devices.

## Requirements

- **Python**: 3.x (tested with Python 3.9.6)
- **System tools**: `wget` and `curl` are required

## Installation

1. **Clone the repository:**
   ```bash
   git clone git@github.com:HubbleNetwork/hubble-tldm
   cd hubble-tldm
   ```

2. **Set up Python virtual environment:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Running the Service

Start the API server:
```bash
uvicorn dm-api:app --reload
```

The API documentation will be available at: http://127.0.0.1:8000/docs

## API Usage

### Authentication

All API endpoints require authentication using a Bearer token. Include the token in the Authorization header:
```
Authorization: Bearer supersecrettoken
```

### Create a Device

Send a POST request to `/create_device` with a JSON body:

```json
{
  "customer_name": "Test Customer"
}
```

The API will respond with:

```json
{
  "device_id": "02765c6f-6a6e-4da8-8612-54f7a009831b",
  "key": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "customer_name": "Test Customer",
  "registration_script": "curl -H 'Authorization: Bearer supersecrettoken' -s http://localhost:8000/provision.sh | bash -s -- --device-id 02765c6f-6a6e-4da8-8612-54f7a009831b --key a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

### List Devices

Send a GET request to `/devices` to retrieve all registered devices.

### Download Files

- **Provisioning script**: `GET /provision.sh`
- **JLink tools**: `GET /jlink.tar.gz`
- **Firmware image**: `GET /zephyr.hex`
- **Provisioning key script**: `GET /provision_key.py`
