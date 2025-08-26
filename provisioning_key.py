#!/usr/bin/env python3
#
# Copyright (c) 2025 HubbleNetwork
#
# SPDX-License-Identifier: Apache-2.0

import argparse
import base64
import sys
import time

import serial
import subprocess


SLEEP_TIME = 0.05


def provision_key(key: str, term: str, encoded: bool) -> None:
    try:
        subprocess.run(
            ["JLinkExe"],
            input="connect\nEFR32MG24BXXXF1536\nS\n4000\nReset\nexit\n",
            text=True,
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error resetting device: {e}", file=sys.stderr)
        sys.exit(1)

    # give enough time to reset
    time.sleep(3)

    with open(key, "rb") as f:
        key_data = bytearray(f.read())
        if encoded:
            key_data = bytearray(base64.b64decode(key_data))

    try:
        ser = serial.Serial(port=term, baudrate=115200, timeout=1)
        ser.reset_input_buffer()
    except serial.SerialException as e:
        print(f"{e}", file=sys.stderr)
        sys.exit(1)

    # provision the key
    for x in key_data:
        ser.write(bytes([x]))
        time.sleep(SLEEP_TIME)

    # then provision the utc time (in ms)
    utc_ms = int(time.time() * 1000)
    frame = f"{utc_ms}\n".encode("ascii")
    for b in frame:
        ser.write(bytes([b]))
        time.sleep(SLEEP_TIME)


def parse_args() -> None:
    """
    Provisioning key to a device using serial port.

    The device must be listening on the serial port and be ready to receive
    the key.

    usage: provisioning_key.py [-h] [-b] path/to/key /path/to/serial
    """

    global args

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter, allow_abbrev=False)

    parser.add_argument("key",
                        help="The key to provision")
    parser.add_argument("serial",
                        help="The serial port connected to the device")
    parser.add_argument("-b", "--base64",
                        help="The key is encoded in base64", action='store_true', default=False)
    args = parser.parse_args()


def main():
    parse_args()

    provision_key(args.key, args.serial, args.base64)


if __name__ == '__main__':
    main()
