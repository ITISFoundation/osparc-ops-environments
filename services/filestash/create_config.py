"""
Parses the configuration template and injects it where the platform expects it
Notes:
- $ must be escaped with $$ in the template file
"""

import os
from pathlib import Path
from string import Template

from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATE_PATH = SCRIPT_DIR / "filestash_config.json.template"
CONFIG_JSON = Path(__file__).resolve().parent / "filestash_config.json"


def strtobool(val):
    """
    Convert a string representation of truth to True or False.

    True values are 'y', 'yes', 't', 'true', 'on', and '1';
    False values are 'n', 'no', 'f', 'false', 'off', and '0'.
    Raises ValueError if 'val' is anything else.
    """
    val = val.lower()

    if val in ("y", "yes", "t", "true", "on", "1"):
        return True

    if val in ("n", "no", "f", "false", "off", "0"):
        return False

    raise ValueError(f"invalid truth value {val}")


def patch_env_vars() -> None:
    endpoint = os.environ["S3_ENDPOINT"]
    if not endpoint.startswith("http"):
        protocol = "https" if strtobool(os.environ["S3_SECURE"].lower()) else "http"
        endpoint = f"{protocol}://{endpoint}"

    os.environ["S3_ENDPOINT"] = endpoint


def main() -> None:
    load_dotenv()
    patch_env_vars()

    assert TEMPLATE_PATH.exists()

    template_content = TEMPLATE_PATH.read_text()

    config_json = Template(template_content).substitute(os.environ)

    assert CONFIG_JSON.parent.exists()
    CONFIG_JSON.write_text(config_json)

    # path of configuration file is exported as env var
    print(f"{CONFIG_JSON}")


if __name__ == "__main__":
    main()
