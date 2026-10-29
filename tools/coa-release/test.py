"""Offline community addon/package checks. Never connects to a game or server."""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--lua-libs", type=Path)
options = parser.parse_args()
if options.lua_libs:
    sys.path.insert(0, str(options.lua_libs.resolve(strict=True)))
from lupa.lua51 import LuaRuntime


def run_lua(path, addon):
    lua = LuaRuntime()
    assert lua.eval("_VERSION") == "Lua 5.1"
    lua.globals().arg = lua.table_from({0: path.as_posix(), 1: addon.as_posix()})
    lua.execute(path.read_text(encoding="utf-8"), name=path.as_posix())


run_lua(ROOT / "tools/coa-addon-tests/test_core.lua", ROOT / "GMCommandCenter_CoA")
run_lua(ROOT / "tools/coa-gathering-tests/cases.lua", ROOT / "CoAGatheringAlerts")
run_lua(ROOT / "tools/coa-release/test_resource.lua", ROOT / "COAResourceMonitor")
spec = importlib.util.spec_from_file_location("lfg_tests", ROOT / "tools/coa-release/test_lfg.py")
lfg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lfg)
result = unittest.TextTestRunner(verbosity=1).run(unittest.defaultTestLoader.loadTestsFromModule(lfg))
if not result.wasSuccessful():
    raise SystemExit(1)
spec = importlib.util.spec_from_file_location("coa_package", ROOT / "tools/coa-release/package.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)
with tempfile.TemporaryDirectory(prefix="coa-package-test-") as directory:
    first, second = Path(directory) / "one", Path(directory) / "two"
    manifest = package.build(first)
    assert package.build(second) == manifest
    assert {p.name: p.read_bytes() for p in first.iterdir()} == {p.name: p.read_bytes() for p in second.iterdir()}
    alternate = Path(directory) / "crlf-source"
    alternate.mkdir()
    shutil.copyfile(ROOT / "coa-addons.json", alternate / "coa-addons.json")
    for entry in manifest["packages"]:
        (alternate / entry["id"]).mkdir()
        for name in entry["files"]:
            text = (ROOT / entry["id"] / name).read_text(encoding="utf-8")
            (alternate / entry["id"] / name).write_bytes(text.replace("\n", "\r\n").encode("utf-8"))
    package.ROOT = alternate
    assert package.build(Path(directory) / "crlf-release") == manifest
    for entry in manifest["packages"]:
        with zipfile.ZipFile(first / entry["archive"]) as archive:
            assert set(archive.namelist()) == {entry["id"] + "/" + name for name in entry["files"]}
            for name, expected in entry["files"].items():
                assert package.digest(archive.read(entry["id"] + "/" + name)) == expected
    try:
        package.build(first)
    except ValueError:
        pass
    else:
        raise AssertionError("Existing release output was overwritten")
print("PACKAGE TESTS PASSED: four complete deterministic packages across LF/CRLF checkouts, per-file/archive hashes, TOC coverage, no overwrite")
print("Offline scope only. LFG accepted-DBC validation is skipped without the external game data; real rendering, sound and server acceptance are separate.")
