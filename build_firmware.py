from fastapi import Request
from fastapi.responses import JSONResponse
import subprocess

@app.post("/build_firmware")
async def build_firmware(req: Request):
    data = await req.json()
    device_id = data["device_id"]
    board = data["board"]

    # Trigger AWS Lambda or container build process
    try:
        result = subprocess.run([
            "python3", "build_firmware.py", device_id, board
        ], capture_output=True, text=True)
        firmware_url = f"http://localhost:8000/firmwares/{device_id}.bin"
        return JSONResponse(content={"firmware_url": firmware_url})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
