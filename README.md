# Hubble TLDM

A device management API service.

## Installation

1. Clone the repository:
```bash
git clone git@github.com:HubbleNetwork/hubble-tldm
cd hubble-tldm
```

2. Set up Python virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Running the Service

Start the API server:
```bash
uvicorn dm-api:app --reload
```

The API documentation will be available at: http://127.0.0.1:8000/docs

## Usage Example

To create a new device, send a POST request to `/create_device` with a JSON body:

```json
{
  "customer_name": "Test Customer"
}
```

The API will respond with:

```json
{
  "device_id": "02765c6f-6a6e-4da8-8612-54f7a009831b",
  "customer_name": "art",
  "registration_script": "curl -s http://localhost:8000/install.sh | bash -s -- --device-id 02765c6f-6a6e-4da8-8612-54f7a009831b"
}
```

## Other Dependencies

`wget`, `curl` are required