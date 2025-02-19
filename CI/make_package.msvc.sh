#!/usr/bin/env bash
# Add a param to input the MSVC version used instead of assuming it
set -e

if [ -z $1 ]; then
    echo "No build type provided to generator script! Failing!"
    exit 22
fi

if [ $1 == "RelWithDebInfo" ]; then
    BUILD_TYPE=Debug # This is a ninja thing
else
    BUILD_TYPE=$1 # No, this doesn't ever need to be quoted
fi


PACKAGE_REQS=( \
                   "dreamweave.exe" \
                       "dreamweave-browser.exe" \
                       "dreamweave-server.exe" \
                       "openmw-launcher.exe" \
                       "openmw-wizard.exe" \
                       "openmw-iniimporter.exe" \
		       "defaults.bin" \
		       "defaults-cs.bin" \
		       "dreamweave-client-default.cfg" \
		       "dreamweave-server-default.cfg" \
		       "gamecontrollerdb.txt" \
		       "openmw.cfg" \
    )

DOCS=( \
               "dreamweave-credits.md" \
               "tes3mp-credits.md" \
               "dreamweave-changelog.md" \
               "AUTHORS.md" \
               "LICENSE" \
    )

mkdir dreamweave-build \
    && mv MSVC2019_64_Ninja/$BUILD_TYPE/resources/ dreamweave-build/ \
    && mv MSVC2019_64_NINJA/$BUILD_TYPE/osgPlugins-3.6.5 dreamweave-build \
    && mv MSVC2019_64_NINJA/$BUILD_TYPE/platforms dreamweave-build \
    && cd dreamweave-build

for DOC in "${DOCS[@]}"; do
    find .. -name "$DOC" -exec mv "{}" . \; 2> /dev/null || true
done

for REQ in "${PACKAGE_REQS[@]}"; do
    find .. -name "$REQ" -exec mv "{}" . \; 2> /dev/null || true
done

find ../MSVC2019_64_Ninja/$BUILD_TYPE -name "*.dll" -exec cp  "{}" . \;

git clone https://github.com/DreamWeave-MP/CoreScripts.git server/

echo "Acquiring IO2 . . ."
curl -o server/lib/io2.dll -L https://github.com/DreamWeave-MP/Lua-io2/releases/download/Stable-CI/io2-MinSizeRel.dll

echo "Acquiring CJson . . ."
curl  -o server/lib/cjson.dll -L https://github.com/DreamWeave-MP/lua-cjson/releases/download/Stable-CI/cjson-MinSizeRel-Windows.dll
