git clone git@github.com:HubbleNetwork/hubble-tldm

cd hubble-tldm

python3 -m venv .venv

source .venv/bin/activate

pip install -r requirements.txt

uvicorn dm-api:app --reload

Open your browser at: http://127.0.0.1:8000/docs. Use POST /create_device with a JSON body like:

{"customer_name": "Test Customer"}

The reply looks like this:

{
  "device_id": "02765c6f-6a6e-4da8-8612-54f7a009831b",
  "customer_name": "art",
  "registration_script": "curl -s http://localhost:8000/install.sh | bash -s -- --device-id 02765c6f-6a6e-4da8-8612-54f7a009831b"
}
