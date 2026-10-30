#!/usr/bin/env python3
"""Build the pinned CoA WeakAuras source bundle; never install into a client.

Copyright (C) 2026 AzerothLabWorks. GPL-2.0-or-later; see COPYING-CoA.
Upstream addon, library and media files retain their original licenses.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import zipfile
import zlib

REPOSITORY = Path(__file__).resolve().parents[2]
MANIFEST = REPOSITORY / "third-party" / "weakauras-coa.json"
PATCH = REPOSITORY / "third-party" / "patches" / "WeakAuras-Icon-cooldown.patch"
OLD = b"      if (cooldown.duration and cooldown.duration > 0.01 and cooldown.duration ~= math.huge and cooldown.expirationTime ~= math.huge) then\n"
NEW = (b"      -- AzerothLabWorks, 2026-10-30: skip cooldown arithmetic until expirationTime exists.\n"
       b"      if (cooldown.duration and cooldown.expirationTime and cooldown.duration > 0.01 and cooldown.duration ~= math.huge and cooldown.expirationTime ~= math.huge) then\n")
ZIP_TIME = (2026, 10, 30, 0, 0, 0)
MAX_FILES = 2000
MAX_BLOB = 32 * 1024 * 1024
MAX_TOTAL = 256 * 1024 * 1024


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(value) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode("utf-8")


def safe_path(name: str) -> str:
    path = PurePosixPath(name)
    if (not name or "\\" in name or ":" in name or "\x00" in name
            or path.is_absolute() or path.as_posix() != name):
        raise ValueError(f"Unsafe package path: {name!r}")
    for part in path.parts:
        if part in (".", "..") or part.endswith((".", " ")):
            raise ValueError(f"Unsafe package component: {name!r}")
        if part.casefold() in (".git", "wtf", "savedvariables"):
            raise ValueError(f"Private/configuration path is forbidden: {name!r}")
        if re.fullmatch(r"(?i)(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?", part):
            raise ValueError(f"Windows device name is forbidden: {name!r}")
    return name


def git(source: Path, *args: str, input_data: bytes | None = None) -> bytes:
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0", GIT_NO_REPLACE_OBJECTS="1")
    result = subprocess.run(["git", "-C", str(source), *args], input=input_data,
                            capture_output=True, check=False, env=env)
    if result.returncode:
        raise ValueError("Cannot read the pinned public Git source: "
                         + result.stderr.decode("utf-8", "replace").strip())
    return result.stdout


def read_source(source: Path, manifest: dict) -> dict[str, bytes]:
    if not source.is_dir():
        raise ValueError("--source must be an existing public Git clone")
    commit = manifest["upstream"]["commit"]
    if git(source, "rev-parse", "HEAD").decode().strip() != commit:
        raise ValueError("Source HEAD differs from the reviewed pinned commit")
    if git(source, "rev-parse", commit + "^{tree}").decode().strip() != manifest["upstream"]["tree"]:
        raise ValueError("Pinned Git tree identity mismatch")
    selected = {}
    objects = []
    seen = set()
    total = 0
    roots = set(manifest["addon_folders"])
    for record in git(source, "ls-tree", "-r", "-l", "-z", commit).split(b"\0"):
        if not record:
            continue
        metadata, raw_name = record.split(b"\t", 1)
        mode, kind, object_id, raw_size = metadata.decode("ascii").split()
        name = raw_name.decode("utf-8")
        if name.split("/", 1)[0] not in roots and name not in ("LICENSE", "README.md"):
            continue
        safe_path(name)
        if mode not in ("100644", "100755") or kind != "blob":
            raise ValueError("Symlinks and non-file objects cannot be packaged: " + name)
        if name.casefold() in seen:
            raise ValueError("Case-colliding package path: " + name)
        seen.add(name.casefold())
        size = int(raw_size)
        if size > MAX_BLOB or total + size > MAX_TOTAL or len(objects) >= MAX_FILES:
            raise ValueError("Pinned source exceeds package size limits")
        objects.append((name, object_id, size))
        total += size
    # Read bounded committed bytes in one call. No working-tree filters or EOL
    # conversion apply, and no checkout/client files are examined.
    batch = io.BytesIO(git(source, "cat-file", "--batch", input_data=
                          "".join(object_id + "\n" for _, object_id, _ in objects).encode("ascii")))
    for name, object_id, size in objects:
        header = batch.readline().decode("ascii").strip().split()
        if header != [object_id, "blob", str(size)]:
            raise ValueError("Git batch object identity mismatch: " + name)
        data = batch.read(size)
        if len(data) != size or batch.read(1) != b"\n":
            raise ValueError("Git blob size mismatch: " + name)
        selected[name] = data
    if batch.read(1):
        raise ValueError("Unexpected trailing Git batch data")
    actual_folders = {name.split("/", 1)[0] for name in selected if "/" in name}
    if actual_folders != roots:
        raise ValueError("Pinned source does not contain exactly the six addon folders")
    addon_count = sum(name.split("/", 1)[0] in roots for name in selected)
    if addon_count != manifest["upstream"]["addon_file_count"]:
        raise ValueError("Pinned addon file inventory count mismatch")
    for name in manifest["required_notices"]:
        if name not in selected:
            raise ValueError("Required original license/attribution is missing: " + name)
    for name, expected in manifest["source_fingerprints"].items():
        if name not in selected or sha256(selected[name]) != expected:
            raise ValueError("Source fingerprint mismatch: " + name)
    return selected


def apply_icon_fix(original: bytes, manifest: dict) -> bytes:
    if sha256(original) != manifest["source_fingerprints"]["WeakAuras/RegionTypes/Icon.lua"]:
        raise ValueError("Unexpected Icon.lua; refusing to guess at patch placement")
    if original.count(OLD) != 1:
        raise ValueError("Cooldown guard context must occur exactly once")
    return original.replace(OLD, NEW, 1)


def patch_bytes(original: bytes, changed: bytes) -> bytes:
    return "".join(difflib.unified_diff(
        original.decode("utf-8").splitlines(True), changed.decode("utf-8").splitlines(True),
        fromfile="a/WeakAuras/RegionTypes/Icon.lua", tofile="b/WeakAuras/RegionTypes/Icon.lua"
    )).encode("utf-8")


def make_payload(source_files: dict[str, bytes], manifest: dict) -> dict[str, bytes]:
    files = dict(source_files)
    icon = "WeakAuras/RegionTypes/Icon.lua"
    files[icon] = apply_icon_fix(files[icon], manifest)
    patch = patch_bytes(source_files[icon], files[icon])
    if PATCH.read_bytes() != patch:
        raise ValueError("Checked-in patch does not match the exact reviewed change")
    files["UPSTREAM-README.md"] = files.pop("README.md")
    files["ALW-PATCHES/WeakAuras-Icon-cooldown.patch"] = patch
    files["ALW-README.md"] = (Path(__file__).parent / "PACKAGE-README.md").read_bytes()
    files["ALW-CHANGES.md"] = (Path(__file__).parent / "CHANGES.md").read_bytes()
    files["ALW-PROVENANCE.json"] = json_bytes(manifest)
    files["ALW-FILE-HASHES.json"] = json_bytes({
        "schema": 1, "algorithm": "sha256", "excludes_self": True,
        "files": {name: {"sha256": sha256(data), "bytes": len(data)}
                  for name, data in sorted(files.items())}
    })
    for name in files:
        safe_path(name)
    return files


def zip_bytes(files: dict[str, bytes]) -> bytes:
    # Fixed compression, order and metadata. The build report records Python and
    # zlib versions because different deflate implementations can change bytes.
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=9, allowZip64=False) as archive:
        for name, data in sorted(files.items()):
            safe_path(name)
            item = zipfile.ZipInfo(name, ZIP_TIME)
            item.create_system = 3
            item.external_attr = (0o100644 << 16)
            item.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(item, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return output.getvalue()


def build(source: Path, output: Path) -> dict:
    source = source.resolve(strict=True)
    output = output.absolute()
    if output.exists() or output.is_symlink():
        raise ValueError("--output must be a new directory; existing paths are never overwritten")
    parent = output.parent.resolve(strict=True)
    output = parent / output.name
    if source == output or source in output.parents:
        raise ValueError("Output must be outside the read-only source clone")
    if any(part.casefold() in ("interface", "wtf", "savedvariables") for part in output.parts):
        raise ValueError("Choose an artifact output directory, not a game configuration/addon path")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    source_files = read_source(source, manifest)
    payload = make_payload(source_files, manifest)
    archive = zip_bytes(payload)
    report = {
        "schema": 1, "package": manifest["package"], "sha256": sha256(archive),
        "bytes": len(archive), "files": len(payload),
        "source_commit": manifest["upstream"]["commit"],
        "source_tree": manifest["upstream"]["tree"],
        "source_file_hashes": {name: sha256(data) for name, data in sorted(source_files.items())},
        "package_file_hashes": {name: sha256(data) for name, data in sorted(payload.items())},
        "modified_upstream_files": ["WeakAuras/RegionTypes/Icon.lua"],
        "preserves_original_notices": True, "includes_personal_settings": False,
        "toolchain": {"python": sys.version.split()[0], "zlib": zlib.ZLIB_RUNTIME_VERSION,
                      "compression": "ZIP_DEFLATED level 9"},
    }
    # All input validation and assembly happens before creating the fresh output.
    output.mkdir(exist_ok=False)
    with (output / manifest["package"]).open("xb") as stream:
        stream.write(archive)
    with (output / "SHA256SUMS.txt").open("xb") as stream:
        stream.write((report["sha256"] + "  " + manifest["package"] + "\n").encode("ascii"))
    with (output / "build-report.json").open("xb") as stream:
        stream.write(json_bytes(report))
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path,
                        help="Read-only Git clone with HEAD at the pinned public commit")
    parser.add_argument("--output", required=True, type=Path,
                        help="Fresh artifact directory with an existing parent; never a client path")
    args = parser.parse_args()
    try:
        report = build(args.source, args.output)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"WeakAuras package refused: {error}\n")
    print(json.dumps({key: report[key] for key in ("package", "sha256", "bytes", "files", "source_commit")}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
