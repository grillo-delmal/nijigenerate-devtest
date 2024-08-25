#!/usr/bin/env bash

set -e

flatpak-builder --default-branch=nightly --force-clean --repo=./repo-dir ./build-dir io.github.grillo_delmal.nijigenerate.yml

flatpak build-bundle \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    ./repo-dir \
    nijigenerate.x86_64.flatpak \
    io.github.grillo_delmal.nijigenerate nightly
flatpak build-bundle \
    --runtime \
    ./repo-dir \
    nijigenerate.x86_64.debug.flatpak \
    io.github.grillo_delmal.nijigenerate.Debug nightly

# flatpak --user -y install nijigenerate.x86_64.flatpak
# flatpak --user -y install nijigenerate.x86_64.debug.flatpak