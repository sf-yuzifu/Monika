"""Check manifest-derived release versions and rejection of inconsistent metadata."""
import json
import unittest
from unittest.mock import patch
from release_tag import version_code


class ReleaseVersionTests(unittest.TestCase):
    def test_manifest_is_version_source(self):
        value = {"downloads": {"a": {"versionCode": 7}, "b": {"versionCode": 7}}}
        with patch("pathlib.Path.read_text", return_value=json.dumps(value)):
            self.assertEqual(version_code("v1.2.0"), 7)
            self.assertEqual(version_code("v2.0.0"), 7)

    def test_invalid_manifest(self):
        cases = [{}, {"downloads": {}}, {"downloads": {"a": {}}},
                 {"downloads": {"a": {"versionCode": True}}},
                 {"downloads": {"a": {"versionCode": "7"}}},
                 {"downloads": {"a": {"versionCode": 0}}},
                 {"downloads": {"a": {"versionCode": 2**32}}},
                 {"downloads": {"a": {"versionCode": 7}, "b": {"versionCode": 8}}}]
        for value in cases:
            with self.subTest(value=value), patch("pathlib.Path.read_text", return_value=json.dumps(value)):
                with self.assertRaises(ValueError): version_code("v1.0.0")

    def test_invalid_tag(self):
        for tag in ["1.2.3", "v1.2", "v1.2.3-beta", "v01.2.3"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError): version_code(tag)


if __name__ == "__main__": unittest.main()
