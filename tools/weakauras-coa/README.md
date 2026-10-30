# Reproducible CoA WeakAuras source package

Requirements: Python 3.10+ and Git. This tool only reads a pinned public Git clone
and creates a **new** output directory. It never installs into a game client and
does not read user aura settings.

From the addons repository root:

```powershell
git clone --no-checkout https://github.com/Thinato/WeakAuras-Ascension.git C:/Build/WeakAuras-Ascension
git -C C:/Build/WeakAuras-Ascension checkout --detach 5741c0cd6ee021a954b83ea6c69edf8bd0bba196
python tools/weakauras-coa/test_build.py --source C:/Build/WeakAuras-Ascension
python tools/weakauras-coa/build.py --source C:/Build/WeakAuras-Ascension --output C:/Build/WeakAuras-CoA-output
```

Use your own existing parent directory and fresh clone/output paths. A clone at
a different HEAD is refused. Dirty working-tree contents are ignored: all inputs
come directly from the pinned committed blobs. Keep the original upstream fork
and root/nested licenses; the GitHub-generated ZIP omits some of those licenses
via `export-ignore` and is not a valid input to this builder.

Outputs are `WeakAuras-CoA-5.21.2-alw.1.zip`, `SHA256SUMS.txt` and
`build-report.json`. The ZIP uses stable order, timestamps, permissions and
deflate level 9. Its bytes are reproducible with the same Python/zlib toolchain,
recorded in the report; local checkout EOL settings do not affect it. Different
deflate implementations may produce different ZIP bytes with identical file
hashes. The report includes complete original and packaged file hashes.

Only the existing G1 expiration-time nil guard changes addon code. The package
adds a dated comment and records the unified patch. The Lua source remains in
the ZIP. Tests use the public source and disposable temporary outputs; no client
or SavedVariables is consulted.

See `PACKAGE-README.md` for manual installation, separate native range-library
repair, attribution and third-party media conditions. This package does not add
WeakAuras to the four-addon installer or change the `g1-20261029` bundle.
