#!/bin/sh
#
# Lints the whole repository against the root .swiftlint.yml. Invoked automatically by the SwiftLint
# build pre-action on the shared Secure-Box-Package scheme, right after the SwiftFormat one, so the
# formatter has already fixed whatever it can; safe to run by hand from anywhere. `swift build` runs
# no pre-action, so run both scripts by hand there.
#
#     Tools/SwiftLint/lint.sh
#
# Arguments are passed on to `swiftlint lint`. The pre-action passes --strict, which fails on warnings
# too: a pre-action cannot put a warning in Xcode's issue navigator, so a violation either stops the
# build with SwiftLint's message or goes unseen in the log.
#
# The binary is downloaded from the pinned GitHub release on first use and cached outside the
# repository, so a fresh clone still needs no setup and every machine runs the same version.
# It is NOT committed: git does not carry extended attributes, so a git client can re-stamp
# com.apple.quarantine onto the checked-out binary and Gatekeeper then blocks it (the release binary
# is adhoc-signed, not notarized). curl and unzip set no quarantine, which is what makes the cached
# copy runnable.
#
# To bump SwiftLint, change VERSION and CHECKSUM together — nothing else. CHECKSUM is
# `shasum -a 256` of the release's portable_swiftlint.zip.

set -eu

VERSION="0.65.1"
CHECKSUM="c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0"

# This script lives in Tools/SwiftLint/, so the repository root is two levels up.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Not `swiftlint/`: on a case-insensitive volume that is SwiftLint's own cache, `SwiftLint/<version>/`.
CACHE="${XDG_CACHE_HOME:-$HOME/Library/Caches}/swiftlint-binary/$VERSION"
BINARY="$CACHE/swiftlint"

if [ ! -x "$BINARY" ]; then
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT INT TERM

    echo "note: downloading SwiftLint $VERSION"
    curl -fsSL -o "$TMP/swiftlint.zip" \
        "https://github.com/realm/SwiftLint/releases/download/$VERSION/portable_swiftlint.zip"

    # Verified before it is ever unpacked: the binary is adhoc-signed, so this checksum is the only
    # thing standing between a tampered release asset and a tool that runs on every build.
    echo "$CHECKSUM  $TMP/swiftlint.zip" | shasum -a 256 -c - >/dev/null

    unzip -qo "$TMP/swiftlint.zip" -d "$TMP"
    chmod +x "$TMP/swiftlint"
    mkdir -p "$CACHE"
    # Atomic within one filesystem, so a second build racing this one either sees no binary yet or
    # sees the finished copy — never a half-written one.
    mv -f "$TMP/swiftlint" "$BINARY"

    rm -rf "$TMP"
    trap - EXIT INT TERM
fi

# SwiftLint reads .swiftlint.yml, and resolves its `excluded` paths, from the working directory.
cd "$ROOT"
exec "$BINARY" lint --quiet "$@"
