#!/usr/bin/env bash

mkdir -p dep.build

# Delete the old working directory
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Download nijigenerate
pushd dep.build
git clone https://github.com/nijigenerate/nijigenerate.git
popd #dep.build

cat <<EOL > latest-nijigenerate.yml
type: git
url: https://github.com/nijigenerate/nijigenerate.git
commit: $(git -C ./dep.build/nijigenerate rev-parse HEAD)
disable-shallow-clone: true
EOL

