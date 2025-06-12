import sys
import os
import subprocess

DEVICE_ID = sys.argv[1]
BOARD = sys.argv[2]

os.environ['ZEPHYR_BASE'] = '/opt/zephyr'

output = subprocess.run([
    "west", "build", "-b", BOARD, "-d", "build", "--", f"-DCONFIG_DEVICE_ID=\"{DEVICE_ID}\""
])

# Assume build produces build/zephyr/zephyr.bin
subprocess.run(["cp", "build/zephyr/zephyr.bin", f"firmwares/{DEVICE_ID}.bin"])
