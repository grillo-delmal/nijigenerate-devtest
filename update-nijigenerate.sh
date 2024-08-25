#!/usr/bin/env bash

mkdir -p dep.build

# Delete the old working directory
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Download nijigenerate
pushd dep.build
git clone https://github.com/nijigenerate/nijigenerate.git
# Fixme Use v0_8 branch until v9 is usable
git -C ./nijigenerate checkout v0_8
popd #dep.build

cat <<EOL > latest-nijigenerate.yml
type: git
url: https://github.com/nijigenerate/nijigenerate.git
commit: $(git -C ./dep.build/nijigenerate rev-parse HEAD)
disable-shallow-clone: true
EOL

