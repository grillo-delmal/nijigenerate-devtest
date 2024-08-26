#!/usr/bin/env bash

set -e

# Apply lib patches
if [ -d "./patches" ]; then 
    pushd patches
    if [ -d "./libs" ]; then
        pushd libs
        if [ ! -z "$(ls -A */ 2> /dev/null)" ]; then 
            for d in * ; do
                if [ -d "$d" ]; then
                    for p in ${d}/*.patch; do 
                        for g in ../../$1/${d}/*/${d}/; do
                            if [ -d "$g" ]; then
                                echo "Patching ${p} in ${g}"
                                cat $p | git -C ${g} apply
                            fi
                        done
                    done
                fi
            done
        fi
        popd
    fi
    popd
fi

# Apply nijigenerate patches
if [ -d "./patches/nijigenerate" ]; then
    for p in ./patches/nijigenerate/*.patch; do
        echo "Patching ${p}"
        cat $p | git -C $2 apply
    done
fi
