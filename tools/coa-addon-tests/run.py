"""Run offline addon tests with Lupa's actual Lua 5.1 backend (no WoW connection)."""
import argparse
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua-libs", type=Path, help="Existing directory containing the isolated lupa package")
    parser.add_argument("--addon", type=Path, default=Path(__file__).resolve().parents[2] / "GMCommandCenter_CoA")
    parser.add_argument("--test", type=Path, default=Path(__file__).with_name("test_core.lua"))
    options = parser.parse_args()
    if options.lua_libs:
        sys.path.insert(0, str(options.lua_libs.resolve(strict=True)))
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(unpack_returned_tuples=True)
    if lua.eval("_VERSION") != "Lua 5.1":
        raise RuntimeError("The addon regression suite requires Lua 5.1")
    script = options.test.resolve(strict=True)
    addon = options.addon.resolve(strict=True)
    lua.globals().arg = lua.table_from({0: script.as_posix(), 1: addon.as_posix()})
    lua.execute(script.read_text(encoding="utf-8"), name=script.as_posix())
    return 0


if __name__ == "__main__":
    sys.exit(main())
