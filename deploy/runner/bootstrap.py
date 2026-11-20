#!/usr/bin/env python3
"""Register the repository runner; keep the short-lived token out of files and logs."""
import json
import subprocess
from pathlib import Path

registration = json.loads(subprocess.check_output([
    "gh", "api", "--method", "POST",
    "repos/FreeSpott/FreeSpot/actions/runners/registration-token",
], text=True))
secret = {
    "apiVersion": "v1", "kind": "Secret",
    "metadata": {"name": "freespot-runner-registration", "namespace": "team-3"},
    "type": "Opaque", "stringData": {"token": registration["token"]},
}
subprocess.run([
    "kubectl", "-n", "team-3", "apply", "--server-side",
    "--field-manager=freespot-runner", "-f", "-",
], input=json.dumps(secret), text=True, check=True)
subprocess.run(["kubectl", "apply", "-f", str(Path(__file__).with_name("runner.yaml"))], check=True)
