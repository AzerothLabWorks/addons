#!/usr/bin/env python3
"""Public-source qualification for the CoA WeakAuras bundle.

Copyright (C) 2026 AzerothLabWorks. GPL-2.0-or-later; see COPYING-CoA.
"""
from __future__ import annotations

import argparse
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build

SOURCE: Path


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(build.MANIFEST.read_text(encoding="utf-8"))
        cls.original = build.read_source(SOURCE, cls.manifest)
        cls.payload = build.make_payload(cls.original, cls.manifest)

    def test_only_one_reviewed_source_change(self):
        modified = [name for name, data in self.original.items()
                    if name != "README.md" and self.payload[name] != data]
        self.assertEqual(modified, ["WeakAuras/RegionTypes/Icon.lua"])
        icon = self.payload[modified[0]]
        self.assertEqual(icon.count(build.NEW), 1)
        self.assertNotIn(build.OLD, icon)
        self.assertIn(b"AzerothLabWorks, 2026-10-30", icon)
        # Reverse the reviewed replacement and require the original bytes.
        self.assertEqual(icon.replace(build.NEW, build.OLD, 1), self.original[modified[0]])

    def test_unknown_icon_and_reapplication_refused(self):
        original = self.original["WeakAuras/RegionTypes/Icon.lua"]
        with self.assertRaisesRegex(ValueError, "Unexpected Icon"):
            build.apply_icon_fix(original + b"-- unexpected\n", self.manifest)
        with self.assertRaisesRegex(ValueError, "Unexpected Icon"):
            build.apply_icon_fix(self.payload["WeakAuras/RegionTypes/Icon.lua"], self.manifest)

    def test_all_notices_are_preserved_verbatim(self):
        for name in self.manifest["required_notices"]:
            self.assertIn(name, self.payload)
            self.assertEqual(self.payload[name], self.original[name])
        self.assertIn(b"GNU GENERAL PUBLIC LICENSE", self.payload["LICENSE"])
        self.assertIn(b"CC0", self.payload["WeakAuras/Libs/Archivist/LICENSE.md"])
        self.assertIn(b"NonCommercial", self.payload["WeakAuras/Media/Creative Commons - Attribution-NonCommercial 3.0.txt"])
        self.assertEqual(self.payload["UPSTREAM-README.md"], self.original["README.md"])

    def test_six_matching_folders_without_private_settings(self):
        roots = set(self.manifest["addon_folders"])
        self.assertEqual({name.split("/")[0] for name in self.payload
                          if name.startswith("WeakAuras")}, roots)
        for name in self.payload:
            parts = [part.lower() for part in Path(name).parts]
            self.assertNotIn("wtf", parts)
            self.assertNotIn("savedvariables", parts)
            self.assertNotIn(".git", parts)
            self.assertFalse(name.lower().endswith((".exe", ".dll", ".mpq", ".bak")))
        self.assertEqual(sum(name.split("/")[0] in roots for name in self.payload), 738)

    def test_zip_is_deterministic_and_hash_inventory_is_complete(self):
        forward = build.zip_bytes(self.payload)
        backward = build.zip_bytes(dict(reversed(list(self.payload.items()))))
        self.assertEqual(forward, backward)
        with zipfile.ZipFile(io.BytesIO(forward)) as archive:
            self.assertEqual(archive.namelist(), sorted(self.payload))
            self.assertEqual(len(archive.namelist()), len(set(archive.namelist())))
            inventory = json.loads(archive.read("ALW-FILE-HASHES.json"))["files"]
            self.assertEqual(set(inventory), set(self.payload) - {"ALW-FILE-HASHES.json"})
            for name, expected in inventory.items():
                self.assertEqual(build.sha256(archive.read(name)), expected["sha256"])
                self.assertEqual(len(archive.read(name)), expected["bytes"])
            for info in archive.infolist():
                self.assertEqual(info.date_time, build.ZIP_TIME)
                self.assertEqual(info.external_attr >> 16, 0o100644)

    def test_invalid_paths_refused(self):
        for name in ("../escape", "/absolute", "a/../escape", "a\\b", "a//b",
                     "C:/escape", "WeakAuras/WTF/a", "SavedVariables/a", ".git/config",
                     "WeakAuras/CON.txt", "WeakAuras/space ", "WeakAuras/trailing."):
            with self.subTest(name=name), self.assertRaises(ValueError):
                build.safe_path(name)

    def test_unexpected_head_and_missing_notice_refused(self):
        wrong = copy.deepcopy(self.manifest)
        wrong["upstream"]["commit"] = "0" * 40
        with self.assertRaisesRegex(ValueError, "HEAD differs"):
            build.read_source(SOURCE, wrong)
        missing = copy.deepcopy(self.manifest)
        missing["required_notices"].append("Missing-LICENSE.txt")
        with self.assertRaisesRegex(ValueError, "Required original license"):
            build.read_source(SOURCE, missing)

    def test_output_is_fresh_and_failure_does_not_overwrite(self):
        with tempfile.TemporaryDirectory(prefix="coa-wa-public-test-") as tmp:
            output = Path(tmp) / "bundle"
            first = build.build(SOURCE, output)
            sentinel = output / "keep.txt"
            sentinel.write_text("untouched", encoding="utf-8")
            before = (output / first["package"]).read_bytes()
            with self.assertRaisesRegex(ValueError, "new directory"):
                build.build(SOURCE, output)
            self.assertEqual(sentinel.read_text(), "untouched")
            self.assertEqual((output / first["package"]).read_bytes(), before)
            second = build.build(SOURCE, Path(tmp) / "second")
            self.assertEqual(first["sha256"], second["sha256"])
            self.assertEqual(first["source_file_hashes"], second["source_file_hashes"])

    def test_source_tree_is_used_instead_of_working_files(self):
        # --no-checkout clones work; the source reader never opens Lua files.
        with patch.object(Path, "read_bytes", side_effect=AssertionError("working file read")):
            again = build.read_source(SOURCE, self.manifest)
        self.assertEqual(again, self.original)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    args, remaining = parser.parse_known_args()
    SOURCE = args.source.resolve(strict=True)
    unittest.main(argv=[__file__, *remaining], verbosity=2)
