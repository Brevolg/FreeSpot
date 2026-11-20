#!/usr/bin/env python3
"""Store GHCR credentials from the OS keychain in Kubernetes, without printing them."""
import base64
import json
import subprocess

username = subprocess.check_output(["gh", "api", "user", "--jq", ".login"], text=True).strip()
token = subprocess.check_output(["gh", "auth", "token"], text=True).strip()
auth = base64.b64encode(f"{username}:{token}".encode()).decode()
config = json.dumps({"auths": {"ghcr.io": {"auth": auth}}})
secret = {
    "apiVersion": "v1", "kind": "Secret",
    "metadata": {"name": "freespot-registry", "namespace": "team-3"},
    "type": "kubernetes.io/dockerconfigjson",
    "data": {".dockerconfigjson": base64.b64encode(config.encode()).decode()},
}
subprocess.run(["kubectl", "-n", "team-3", "apply", "--server-side", "--field-manager=freespot-bootstrap", "-f", "-"], input=json.dumps(secret), text=True, check=True)
subprocess.run(["docker", "login", "ghcr.io", "-u", username, "--password-stdin"], input=token, text=True, check=True)
