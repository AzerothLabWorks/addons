#!/usr/bin/env bash
set -euo pipefail

core_root="${LEGION_CORE_ROOT:-/home/ryan/legion-server-sources/LegionCore-7.3.5V2}"
build_root="${LEGION_BUILD_ROOT:-/home/ryan/legion-server-runtime/build-ubuntu18.04}"
data_root="${LEGION_DATA_ROOT:-/home/ryan/legion-server-runtime/data}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
output_path="${1:-$repo_root/GMCommandCenter_Legion/Equipment}"
binary_path="${TMPDIR:-/tmp}/legion-item-catalog"

mkdir -p "$output_path"

c++ -std=gnu++14 -O2 \
    -I"$core_root/src/common" \
    -I"$core_root/src/common/Configuration" \
    -I"$core_root/src/common/Database" \
    -I"$core_root/src/common/Debugging" \
    -I"$core_root/src/common/Logging" \
    -I"$core_root/src/common/Platform" \
    -I"$core_root/src/common/Threading" \
    -I"$core_root/src/common/Utilities" \
    -I"$core_root/src/server/shared" \
    -I"$core_root/src/server/shared/DataStores" \
    -I"$core_root/src/server/game" \
    -I"$core_root/src/server/game/DataStores" \
    -I"$core_root/dep/fmt" \
    -I/usr/include/mysql \
    "$script_dir/generate.cpp" \
    -o "$binary_path" \
    "$build_root/src/server/shared/libshared.a" \
    "$build_root/src/common/libcommon.a" \
    "$build_root/dep/cds/libcds.a" \
    "$build_root/dep/fmt/libfmt.a" \
    -lmysqlclient -lboost_system -lboost_filesystem -lboost_thread \
    -lboost_program_options -lboost_iostreams -lboost_regex \
    -lssl -lcrypto -lz -lpthread -ldl

"$binary_path" "$data_root/dbc/enUS" "$output_path"
