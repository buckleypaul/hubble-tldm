from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from uuid import uuid4
from typing import Dict, Optional

# Initialize FastAPI application
app = FastAPI()

# In-memory storage for devices
devices: Dict[str, dict] = {}

# Simple token for demonstration
AUTH_TOKEN = "supersecrettoken"

class DeviceCreateRequest(BaseModel):
    """Request model for creating a new device.
    
    Attributes:
        customer_name (str): Name of the customer who owns the device
    """
    customer_name: str

class DeviceInfo(BaseModel):
    """Response model containing device information.
    
    Attributes:
        device_id (str): Unique identifier for the device
        customer_name (str): Name of the customer who owns the device
        registration_script (str): Shell script command to register the device
    """
    device_id: str
    customer_name: str
    registration_script: str

@app.post("/create_device", response_model=DeviceInfo)
def create_device(
    request: DeviceCreateRequest,
    authorization: Optional[str] = Header(None)
):
    if authorization != f"Bearer {AUTH_TOKEN}":
        raise HTTPException(status_code=401, detail="Unauthorized")

    device_id = str(uuid4())
    registration_script = (
        f"curl -H 'Authorization: Bearer {AUTH_TOKEN}' -s http://localhost:8000/install.sh | bash -s -- --device-id {device_id}"
    )
    devices[device_id] = {
        "customer_name": request.customer_name,
        "device_id": device_id,
        "registration_script": registration_script
    }
    return DeviceInfo(device_id=device_id, customer_name=request.customer_name, registration_script=registration_script)

@app.get("/devices")
def list_devices():
    """List all registered devices.
    
    Returns:
        list: List of all registered devices with their information
    """
    return list(devices.values())
