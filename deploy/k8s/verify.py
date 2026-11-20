#!/usr/bin/env python3
"""Smoke-check the actual Ingress URL, including assets and protected sensor API."""
import json
import sys
from html.parser import HTMLParser
from urllib.error import HTTPError
from urllib.parse import urljoin, urlsplit
from urllib.request import Request, urlopen

base = sys.argv[1].rstrip("/") + "/"


def get(path):
    with urlopen(urljoin(base, path), timeout=10) as response:
        return response.read(), response.headers.get("Content-Type", "")


class Assets(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "script" and attrs.get("src"):
            self.urls.append(attrs["src"])
        if tag == "link" and attrs.get("href"):
            self.urls.append(attrs["href"])


assert json.loads(get("ready")[0]) == {"status": "ok"}
assert json.loads(get("health")[0]) == {"status": "ok"}
spots = json.loads(get("api/spots")[0])
assert len(spots) == 40, f"Expected 40 parking spots, got {len(spots)}"
assets = Assets()
assets.feed(get("")[0].decode())
assert assets.urls, "No frontend assets found"
for asset in assets.urls:
    body, content_type = get(asset)
    assert body and "text/html" not in content_type, f"Broken asset: {asset}"
prefix = urlsplit(base).path.rstrip("/")
assert prefix + "/openapi.json" in get("docs")[0].decode()
schema = json.loads(get("openapi.json")[0])
if prefix:
    assert {"url": prefix} in schema["servers"]
request = Request(urljoin(base, "api/sensors/events"), data=json.dumps({"spot_id": "A01", "occupied": False}).encode(), headers={"Content-Type": "application/json"})
try:
    urlopen(request, timeout=10)
except HTTPError as error:
    assert error.code == 401, f"Expected missing API key to return 401, got {error.code}"
else:
    raise AssertionError("Sensor endpoint accepted an unauthenticated request")
print(f"Verified {base}: health, database readiness, 40 spots, {len(assets.urls)} assets, Swagger, sensor authentication")
