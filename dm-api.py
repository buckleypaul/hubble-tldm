from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import FileResponse
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from uuid import uuid4
from typing import Dict, Optional

# Initialize FastAPI application
app = FastAPI()
security = HTTPBearer()

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
        key (str): Key for the device
        customer_name (str): Name of the customer who owns the device
        registration_script (str): Shell script command to register the device
    """
    device_id: str
    key: str
    customer_name: str
    registration_script: str

@app.post("/create_device", response_model=DeviceInfo)
def create_device(
    request: DeviceCreateRequest,
    token: str = Depends(security)
):
    print(f"Token: {token}")
    if token.credentials != AUTH_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")

    device_id = str(uuid4())
    key = str(uuid4())
    registration_script = (
        f"curl -H 'Authorization: Bearer {AUTH_TOKEN}' -s http://localhost:8000/provision.sh | bash -s -- --device-id {device_id} --key {key}"
    )
    devices[device_id] = {
        "customer_name": request.customer_name,
        "device_id": device_id,
        "key": key,
        "registration_script": registration_script
    }
    return DeviceInfo(device_id=device_id, key=key, customer_name=request.customer_name, registration_script=registration_script)

@app.get("/devices")
def list_devices(token: str = Depends(security)):
    """List all registered devices.
    
    Returns:
        list: List of all registered devices with their information
    """
    if token.credentials != AUTH_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    return list(devices.values())

@app.get("/provision.sh")
def get_install_script():
    """Download device provisioning script.
    
    Returns:
        FileResponse: Device provisioning shell script
    """
    return FileResponse("provision.sh", media_type="text/x-sh")

@app.get("/jlink.tar.gz")
def get_jlink_tools():
    """Download JLink tools archive.
    
    Returns:
        FileResponse: JLink tools archive file
    """
    return FileResponse("jlink.tar.gz", media_type="application/gzip")

@app.get("/zephyr.hex")
def get_firmware_image():
    """Download Zephyr firmware image.
    
    Returns:
        FileResponse: Zephyr firmware hex file
    """
    return FileResponse("zephyr.hex", media_type="application/octet-stream")

@app.get("/provisioning_key.py")
def get_provisioning_key():
    """Download provisioning key Python script.
    
    Returns:
        FileResponse: Provisioning key Python script file
    """
    return FileResponse("provisioning_key.py", media_type="text/x-python")
