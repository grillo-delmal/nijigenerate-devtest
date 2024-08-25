#!/usr/bin/env bash

source ./scripts/semver.sh

# Create and update nijigenerate metadata if it doesn't exist
[ ! -d "./dep.build/nijigenerate/.git" ] && ./update-nijigenerate.sh

VERSION=$(semver ./dep.build/nijigenerate)
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
DATE=$(date -I -u )

sed -i -E \
    "s/<release .*>/<release version=\"$VERSION.$TIMESTAMP\" date=\"$DATE\">/" \
    io.github.grillo_delmal.nijigenerate.metainfo.xml