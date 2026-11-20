"""Check the credential boundary: validate access before changing cluster state."""
import base64
import importlib.util
import io
import json
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError

spec = importlib.util.spec_from_file_location("registry_secret", Path(__file__).with_name("registry-secret.py"))
registry = importlib.util.module_from_spec(spec)
spec.loader.exec_module(registry)


class RegistrySecretTests(unittest.TestCase):
    def test_verified_credentials_are_sent_only_through_stdin(self):
        responses = [io.BytesIO(json.dumps(data).encode()) for data in (
            {"token": "registry-bearer"}, {}, {"token": "registry-bearer"}, {},
        )]
        with patch.dict(registry.os.environ, {"GHCR_USERNAME": "test-user", "GHCR_READ_TOKEN": "dummy-read-token", "IMAGE_TAG": "sha-test"}, clear=True), patch.object(registry, "urlopen", side_effect=responses) as request, patch.object(registry.subprocess, "run") as command, patch("builtins.print") as output:
            registry.main()
        args, kwargs = command.call_args
        self.assertNotIn("dummy-read-token", " ".join(args[0]))
        secret = json.loads(kwargs["input"])
        config = json.loads(base64.b64decode(secret["data"][".dockerconfigjson"]))
        self.assertEqual(base64.b64decode(config["auths"]["ghcr.io"]["auth"]).decode(), "test-user:dummy-read-token")
        self.assertEqual(secret["type"], "kubernetes.io/dockerconfigjson")
        self.assertEqual(request.call_args_list[1].args[0].full_url, "https://ghcr.io/v2/freespott/freespot-backend/manifests/sha-test")
        self.assertEqual(request.call_args_list[3].args[0].full_url, "https://ghcr.io/v2/freespott/freespot-frontend/manifests/sha-test")
        self.assertNotIn("dummy-read-token", str(output.call_args_list))

    def test_denied_package_access_preserves_cluster_secret(self):
        responses = [io.BytesIO(b'{"token":"bearer"}'), io.BytesIO(b'{}'), HTTPError("https://ghcr.io/token", 403, "Forbidden", {}, None)]
        with patch.dict(registry.os.environ, {"GHCR_USERNAME": "test-user", "GHCR_READ_TOKEN": "dummy-read-token"}, clear=True), patch.object(registry, "urlopen", side_effect=responses), patch.object(registry.subprocess, "run") as command:
            with self.assertRaises(SystemExit) as error:
                registry.main()
        command.assert_not_called()
        self.assertIn("HTTP 403", str(error.exception))
        self.assertNotIn("dummy-read-token", str(error.exception))

    def test_missing_secret_fails_without_prompt_in_ci(self):
        with patch.dict(registry.os.environ, {"GHCR_USERNAME": "test-user"}, clear=True), patch.object(registry.sys.stdin, "isatty", return_value=False), patch.object(registry.getpass, "getpass") as prompt, patch.object(registry.subprocess, "run") as command:
            with self.assertRaises(SystemExit):
                registry.main()
        prompt.assert_not_called()
        command.assert_not_called()


if __name__ == "__main__":
    unittest.main()
