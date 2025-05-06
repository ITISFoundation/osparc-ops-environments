#!/usr/bin/env -S uv --quiet run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "typer",
#   "requests",
# ]
# ///
import json
import warnings
from typing import Optional

import requests
import typer
from requests.auth import HTTPBasicAuth

warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)


app = typer.Typer(help="Graylog Notification Cleanup Tool")


def delete_notification(
    session: requests.Session,
    base_url: str,
    notification_id: str,
    notification_type: str,
) -> bool:
    url = f"{base_url}/api/system/notifications/{notification_type}/{notification_id}"

    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0",
        "Accept": "application/json",
        "Accept-Language": "en-US,en;q=0.5",
        "X-Requested-With": "XMLHttpRequest",
        "X-Requested-By": "XMLHttpRequest",
        "Content-Type": "application/json",
        "Origin": base_url,
        "Referer": f"{base_url}/system/overview",
    }

    try:
        response = session.delete(url, headers=headers)
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        typer.echo(f"Error deleting notification {notification_id}: {str(e)}", err=True)
        typer.echo(f"Response content: {response.text}", err=True)
        return False


@app.command()
def cleanup(
    graylog_url: str = typer.Option(
        default=...,
        envvar="GRAYLOG_HTTP_EXTERNAL_URI",
        prompt=False,
        help="Base Graylog URL",
    ),
    username: Optional[str] = typer.Option(
        None,
        "--username",
        "-u",
        envvar="SERVICES_USER",
        prompt=False,
        help="Graylog username",
    ),
    password: Optional[str] = typer.Option(
        None,
        "--password",
        "-p",
        envvar="SERVICES_PASSWORD",
        prompt=False,
        hide_input=True,
        help="Graylog password",
    ),
    dry_run: bool = typer.Option(False, help="Simulate cleanup without deleting"),
    force: bool = typer.Option(False, "--force", "-f", help="Skip confirmation prompt"),
):
    # Validate authentication options
    if not (username and password):
        typer.echo(
            "Error: You must provide either username/password or an API token", err=True
        )
        raise typer.Exit(code=1)
    graylog_url = graylog_url.rstrip("/")

    # Fetch notifications
    auth = HTTPBasicAuth(username, password) if username else None
    headers = {
        "Referer": f"{graylog_url}/system/overview",
        "X-Requested-With": "XMLHttpRequest",
        "X-Requested-By": "XMLHttpRequest",
        "X-Graylog-No-Session-Extension": "true",
        "Content-Type": "application/json",
        "Connection": "keep-alive",
        # Existing headers if there are any; otherwise, remove this comment
    }
    notifications_url = f"{graylog_url}/api/system/notifications"
    session = requests.Session()
    session.verify = False
    session.auth = auth  # Graylog username is always "admin"
    # Modify the notification fetching section:
    try:
        response = session.get(
            notifications_url, auth=(username, password), headers=headers, verify=True
        )
        response.raise_for_status()

        # Check for empty response
        if not response.content.strip():
            typer.echo("Error: Received empty response from server", err=True)
            raise typer.Exit(code=1)

        notifications = response.json()["notifications"]
    except json.JSONDecodeError as exc:
        typer.echo(f"Invalid JSON response: {response.text[:200]}", err=True)
        raise typer.Exit(code=1) from exc

    # Display summary
    typer.echo(f"Found {len(notifications)} notifications to process")
    if dry_run:
        typer.echo("Dry run enabled - no changes will be made")

    if not force and not dry_run:
        typer.confirm("Are you sure you want to delete all notifications?", abort=True)

    # Process notifications
    success_count = 0
    # print(notifications[0:5])
    # exit(1)
    for notification in notifications:
        n_type = notification.get("type")
        n_id = notification.get("key")

        if not n_type or not n_id:
            typer.echo(
                f"Skipping notification due to missing type or id: {notification}"
            )
            continue

        if dry_run:
            typer.echo(f"[DRY RUN] Would delete {n_type} notification {n_id}")
            success_count += 1
            continue

        if delete_notification(session, graylog_url, n_id, n_type):
            typer.echo(f"Deleted {n_type} notification {n_id}")
            success_count += 1

    typer.echo(
        f"Successfully processed {success_count}/{len(notifications)} notifications"
    )


if __name__ == "__main__":
    app()
