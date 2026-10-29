"""Build deterministic CoA addon packages without reading a local game installation."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def build(output):
    config = json.loads((ROOT / "coa-addons.json").read_text(encoding="utf-8"))
    if output.exists():
        raise ValueError("Output must be a new directory; existing releases are never overwritten")
    packages = []
    prepared = []
    for addon in config["addons"]:
        identity = addon["id"]
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]{1,63}", identity):
            raise ValueError("Invalid addon identity")
        root = ROOT / identity
        actual = {p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()}
        if actual != set(addon["files"]) or any(p.is_symlink() for p in root.rglob("*")):
            raise ValueError("Unexpected addon source inventory: " + identity)
        files = {name: (root / name).read_text(encoding="utf-8").replace("\r\n", "\n").encode("utf-8")
                 for name in sorted(addon["files"])}
        toc = files[identity + ".toc"].decode("utf-8")
        if not re.search(r"(?m)^## Interface:\s*" + str(addon["interface"]) + r"\s*$", toc):
            raise ValueError("Interface mismatch: " + identity)
        if not re.search(r"(?m)^## Version:\s*" + re.escape(addon["version"]) + r"\s*$", toc):
            raise ValueError("Version mismatch: " + identity)
        loads = [line.strip().replace("\\", "/") for line in toc.splitlines()
                 if line.strip() and not line.startswith("#")]
        if any(name not in files for name in loads):
            raise ValueError("TOC references an absent file: " + identity)
        prepared.append((addon, files))
    output.mkdir(parents=True)
    for addon, files in prepared:
        name = addon["id"] + "-" + addon["version"] + ".zip"
        target = output / name
        with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path, data in files.items():
                info = zipfile.ZipInfo(addon["id"] + "/" + path, (2026, 10, 29, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                archive.writestr(info, data)
        packages.append({"id": addon["id"], "version": addon["version"], "interface": addon["interface"],
                         "requires_server": addon["requires_server"], "archive": name,
                         "sha256": digest(target.read_bytes()),
                         "files": {path: digest(data) for path, data in files.items()}})
    manifest = {"schema": 1, "release_id": config["release_id"],
                "compatibility": config["compatibility"], "packages": packages}
    path = output / "release.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    checksums = [digest(path.read_bytes()) + "  release.json"]
    checksums.extend(p["sha256"] + "  " + p["archive"] for p in packages)
    (output / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="ascii", newline="\n")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    options = parser.parse_args()
    result = build(options.output.resolve())
    print("Packaged " + result["release_id"] + ": " + str(len(result["packages"])) + " addons")
