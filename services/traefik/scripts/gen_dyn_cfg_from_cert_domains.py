import json
import sys
from pathlib import Path

import yaml

if len(sys.argv) != 3:
    raise TypeError(
        "Usage: gen_dyn_cfg_from_cert_domains.py <cert_domains.json> <output_file.yml>"
    )

CERT_DOMAINS_FILE = sys.argv[1]
OUTPUT_FILE = sys.argv[2]
CERT_PATH_PREFIX = Path("/etc/traefik_certs")


def main():
    with open(CERT_DOMAINS_FILE) as f:
        cert_domains = json.load(f)

    main_domains = [item["domain"] for item in cert_domains]

    for ix in range(len(main_domains)):
        if main_domains[ix].startswith("*."):
            main_domains[ix] = main_domains[ix].replace("*.", "_.")

    dyn_cfg = {
        "tls": {
            "certificates": [
                {
                    "certFile": str(CERT_PATH_PREFIX / f"{domain}.crt"),
                    "keyFile": str(CERT_PATH_PREFIX / f"{domain}.key"),
                }
                for domain in main_domains
            ]
        }
    }

    with open(OUTPUT_FILE, "w") as f:
        yaml.dump(dyn_cfg, f)


if __name__ == "__main__":
    main()
