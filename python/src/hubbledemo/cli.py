from __future__ import annotations

import click
import os
import json
import time
import base64
import sys
from datetime import timezone, datetime
from typing import Optional
from hubblenetwork import Organization
from hubbledemo import flash_elf, fetch_elf, patch_elf


def _get_env_or_fail(name: str) -> str:
    val = os.getenv(name)
    if not val:
        raise click.ClickException(f"[ERROR] {name} environment variable not set")
    return val


def _get_org_and_token(org_id, token) -> tuple[str, str]:
    """
    Helper function that checks if the given token and/or org
    are None and gets the env var if not
    """
    if not token:
        token = _get_env_or_fail("HUBBLE_API_TOKEN")
    if not org_id:
        org_id = _get_env_or_fail("HUBBLE_ORG_ID")
    return org_id, token


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
def cli() -> None:
    """Hubble SDK CLI."""
    # top-level group; subcommands are added below


@cli.command("flash")
@click.argument("board", type=str)
@click.option(
    "--org-id",
    "-o",
    type=str,
    default=None,
    show_default=False,
    help="Organization ID (if not using HUBBLE_ORG_ID env var)",
)
@click.option(
    "--token",
    "-t",
    type=str,
    default=None,
    show_default=False,  # show default in --help
    help="Token (if not using HUBBLE_API_TOKEN env var)",
)
def flash(board: str, name: str = None, org_id: str = None, token: str = None) -> None:
    org_id, token = _get_org_and_token(org_id, token)
    org = Organization(org_id=org_id, api_token=token)

    click.secho(f'[INFO] Registering new device with name "{name}"... ', nl=False)
    device = org.register_device()
    click.secho("[SUCCESS]")
    click.secho(f"\tDevice ID:  {device.id}")
    click.secho(f"\tDevice Key: {device.key}")

    click.secho(f"[INFO] Retrieving binary for {board}... ", nl=False)
    buf = fetch_elf(board=board)
    click.secho("[SUCCESS]")

    click.secho("[INFO] Patching key + UTC into binary... ", nl=False)
    patch_elf(buf, device)
    click.secho("[SUCCESS]")

    click.secho("[INFO] Flashing binary onto device... ", nl=False)
    flash_elf(board=board, buf=buf)
    click.secho("[SUCCESS]")

    click.secho(f"{board} successfully flashed and provisioned!")


def main(argv: Optional[list[str]] = None) -> int:
    """
    Entry point used by console_scripts.

    Returns a process exit code instead of letting Click call sys.exit for easier testing.
    """
    try:
        # standalone_mode=False prevents Click from calling sys.exit itself.
        cli.main(args=argv, prog_name="hubbledemo", standalone_mode=False)
    except SystemExit as e:
        return int(e.code)
    except Exception as e:  # safety net to avoid tracebacks in user CLI
        click.secho(f"Unexpected error: {e}", fg="red", err=True)
        return 2
    return 0


if __name__ == "__main__":
    # Forward command-line args (excluding the program name) to main()
    raise SystemExit(main())
