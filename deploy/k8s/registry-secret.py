#!/usr/bin/env python3
"""Validate a dedicated GHCR read token and store it without logging credentials."""
import base64
import getpass
import json
import os
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def main() -> None:
    username = os.environ.get("GHCR_USERNAME", "").strip()
    token = os.environ.get("GHCR_READ_TOKEN", "").strip()
    if not username:
        raise SystemExit("Set GHCR_USERNAME to the GitHub account that owns the read token")
    if not token and sys.stdin.isatty():
        token = getpass.getpass("GHCR read token: ").strip()
    if not token:
        raise SystemExit("Set the repository secret GHCR_READ_TOKEN to a classic PAT with read:packages")

    auth = base64.b64encode(f"{username}:{token}".encode()).decode()
    tag = os.environ.get("IMAGE_TAG", "").strip()
    for component in ("backend", "frontend"):
        repository = f"freespott/freespot-{component}"
        request = Request(
            f"https://ghcr.io/token?service=ghcr.io&scope=repository:{repository}:pull",
            headers={"Authorization": f"Basic {auth}"},
        )
        try:
            with urlopen(request, timeout=20) as response:
                bearer = json.load(response)["token"]
            target = f"manifests/{tag}" if tag else "tags/list"
            request = Request(
                f"https://ghcr.io/v2/{repository}/{target}",
                headers={
                    "Authorization": f"Bearer {bearer}",
                    "Accept": "application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json",
                },
            )
            with urlopen(request, timeout=20) as response:
                response.read()
        except HTTPError as error:
            raise SystemExit(f"Cannot pull {repository}: HTTP {error.code}. Check token scope, expiry and package access.") from None
        except (URLError, TimeoutError):
            raise SystemExit(f"Cannot reach GHCR for {repository}; retry when registry connectivity is restored") from None

    config = json.dumps({"auths": {"ghcr.io": {"auth": auth}}})
    secret = {
        "apiVersion": "v1", "kind": "Secret",
        "metadata": {"name": "freespot-registry", "namespace": "team-3"},
        "type": "kubernetes.io/dockerconfigjson",
        "data": {".dockerconfigjson": base64.b64encode(config.encode()).decode()},
    }
    subprocess.run([
        "kubectl", "-n", "team-3", "apply", "--server-side",
        "--field-manager=freespot-bootstrap", "-f", "-",
    ], input=json.dumps(secret), text=True, check=True)
    print("GHCR pull access verified for both images; freespot-registry updated")


if __name__ == "__main__":
    main()
