#!/usr/bin/env python3
"""Create credentials once; do not rotate credentials of an existing database."""
import json
import secrets
import subprocess

cmd = ["kubectl", "--namespace", "team-3"]
result = subprocess.run(cmd + ["get", "secret", "freespot-secrets", "--ignore-not-found", "-o", "name"], check=True, capture_output=True, text=True)
if result.stdout.strip():
    print("freespot-secrets already exists; credentials preserved")
else:
    password = secrets.token_hex(32)
    secret = {
        "apiVersion": "v1", "kind": "Secret",
        "metadata": {"name": "freespot-secrets", "namespace": "team-3"},
        "type": "Opaque",
        "stringData": {
            "postgres-password": password,
            "database-url": f"postgresql+asyncpg://freespot:{password}@freespot-postgres:5432/freespot",
            "api-key": secrets.token_hex(32),
        },
    }
    subprocess.run(cmd + ["create", "-f", "-"], input=json.dumps(secret), text=True, check=True)
