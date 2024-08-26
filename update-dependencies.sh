#!/usr/bin/env bash

set -e

source ./scripts/semver.sh

CHECKOUT_TARGET=
NIGHTLY=0
VERIFY_NIJI=1
EXT_NIJI=

# Parse options
for i in "$@"; do
    case $i in
        -h|--help)
cat <<EOL
Usage: $0 [OPTION]...
Checks a specific version of nijigenerate, calculates dependencies and stores them 
on a file ready to be used by flatpak-builder.
By default it uses the version defined by the commit hash defined in the
./io.github.grillo_delmal.nijigenerate.yml file

    --target=<string>       Checkout a specific hash/tag/branch instead of
                            reading the one defined on the yaml file.
    --ext-nijigenerate=<string>  Search nijigenerate commit in external file
    --nightly               Will checkout the latest commit from all 
                            dependency repositories.
    --force                 Skip verification.
    --help                  Display this help and exit
EOL
            exit 0
            ;;
        -t=*|--target=*)
            CHECKOUT_TARGET="${i#*=}"
            shift # past argument=value
            ;;
        -e=*|--ext-nijigenerate=*)
            EXT_NIJI="${i#*=}"
            shift # past argument=value
            ;;
        -n|--nightly)
            NIGHTLY=1
            ;;
        -f|--force)
            VERIFY_NIJI=0
            ;;
        -*|--*)
            echo "Unknown option $i"
            exit 1
            ;;
        *)
            ;;
    esac
done

echo "### Verification Stage"
if [ -z ${CHECKOUT_TARGET} ]; then
    if [ -z ${EXT_NIJI} ]; then
        CHECKOUT_TARGET=$(python3 ./scripts/find-nijigenerate-hash.py ./io.github.grillo_delmal.nijigenerate.yml)
    else
        CHECKOUT_TARGET=$(python3 ./scripts/find-nijigenerate-hash.py ${EXT_NIJI} ext)
    fi
fi

# Verify that we are not repeating work 
if [ "${NIGHTLY}" == "0" ] && [ "${VERIFY_NIJI}" == "1" ]; then
    if [ -f "./.dep_target" ]; then
        LAST_PROC=$(cat ./.dep_target)
        if [ "$CHECKOUT_TARGET" == "$LAST_PROC" ]; then
            echo "Dependencies already processed for current commit."
            exit 1
        fi
    fi
fi

echo "### Download Stage"

mkdir -p dep.build

# Delete the old working directory
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

pushd dep.build

# Download nijigenerate
git clone https://github.com/nijigenerate/nijigenerate.git
git -C ./nijigenerate/ checkout $CHECKOUT_TARGET 2>/dev/null

# Download deps
mkdir -p ./deps
pushd deps
git clone https://github.com/nijigenerate/nijilive.git
git clone https://github.com/Inochi2D/i2d-imgui.git

# Download gitver and semver
git clone https://github.com/Inochi2D/gitver.git
git clone https://github.com/dcarp/semver.git
git -C ./semver checkout v0.3.4
popd #deps

if [ "${NIGHTLY}" == "0" ]; then
    # Update repos to their state at nijigenerates commit date
    NIJI_DATE=$(git -C ./nijigenerate/ show -s --format=%ci)
    for d in ./deps/*/ ; do
        DEP_COMMIT=$(git -C $d log --before="$NIJI_DATE" -n1 --pretty=format:"%H" | head -n1)
        git -C $d checkout $DEP_COMMIT 2>/dev/null
    done
fi

# Make sure to apply patches beforehand
popd
bash ./scripts/apply_local_patches.sh dep.build/deps dep.build/nijigenerate
pushd dep.build

echo "### Build Stage"

# Add the dependencies to the nijigenerate's local-packages file
# .The version is calculated to semver format using the git tag
# .the commit hash and the commit distance to the tag.
mkdir -p ./nijigenerate/.dub/packages
for d in ./deps/*/ ; do
    python3 ../scripts/write-local-packages.py \
        ./nijigenerate/.dub/packages/local-packages.json \
        ../deps/ \
        $(basename $d) \
        "$(semver $d)"
done

# Download dependencies and generate the dub.selections.json file in the process
pushd nijigenerate
dub describe  \
    --compiler=ldc2 --build=release --config=linux-full \
    --cache=local \
    >> ../describe.json
popd #nijigenerate

popd #dep.build

echo "### Process Stage"

mv ./dep.build/nijigenerate/dub.selections.json ./dep.build/nijigenerate/dub.selections.json.bak
jq ".versions += {\"semver\": \"$(semver ./dep.build/deps/semver)\", \"gitver\": \"$(semver ./dep.build/deps/gitver)\"}" \
    ./dep.build/nijigenerate/dub.selections.json.bak > ./dep.build/nijigenerate/dub.selections.json

# Generate the dependency file
python3 ./scripts/flatpak-dub-generator.py \
    --output=./dep.build/dub-dependencies.json \
    ./dep.build/nijigenerate/dub.selections.json

# Generate the dub-add-local-sources.json using the generated
# dependency file and adding the correct information to get
# the project libraries.
python3 ./scripts/write-dub-deps.py \
    ./dep.build/dub-dependencies.json \
    ./dub-add-local-sources.json \
    ./dep.build/deps
 
if [ "${NIGHTLY}" == "1" ]; then
    rm -f ./.dep_target
else
    echo "$CHECKOUT_TARGET" > ./.dep_target
fi
