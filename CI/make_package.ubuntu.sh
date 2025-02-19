#!/usr/bin/env bash

set -e

PACKAGE_BINARIES=( \
                   "dreamweave" \
                       "dreamweave-browser" \
                       "dreamweave-server" \
                       "openmw-launcher" \
                       "openmw-wizard" \
                       "openmw-iniimporter" \
    )

#WARN: Linking libtinyxml shouldn't be needed, no version of openmw uses this and it seems to be something weird caused by GitHub CI. Whether this is a problem is tbd.
LIBRARIES=( \
                   "libboost_thread.so" \
                       "libboost_system.so" \
                       "libboost_filesystem.so" \
                       "libboost_program_options.so" \
                       "libboost_iostreams.so" \
                       "libBulletCollision.so" \
                       "libLinearMath-float64.so" \
                       "libBulletCollision-float64.so" \
                       "libbz2.so" \
                       "libLinearMath.so" \
                       "libMyGUIEngine.so" \
                       "libOpenThreads.so" \
                       "libosgAnimation.so" \
                       "libosgDB.so" \
                       "libosgFX.so" \
                       "libosgGA.so" \
                       "libosgParticle.so" \
                       "libosg.so" \
                       "libosgText.so" \
                       "libosgUtil.so" \
                       "libosgViewer.so" \
                       "libosgWidget.so" \
                       "libosgShadow.so" \
                       "libSDL2" \
                       "libts.so" \
                       "libtxc_dxtn.so" \
                       "libunshield.so" \
                       "libuuid.so" \
                       "osgPlugins" \
                       "libtinfo.so" \
                       "liblua5.1.so" \
                       "libpng16.so" \
                       "libtinyxml.so" \
    )

DEFAULTS=( \
           "defaults.bin" \
               "openmw.cfg" \
               "gamecontrollerdb.txt" \
               "dreamweave-client-default.cfg" \
               "dreamweave-server-default.cfg" \
               "tes3mp-credits.md" \
               "tes3mp-changelog.md" \
               "dreamweave-credits.md" \
               "dreamweave-changelog.md" \
               "AUTHORS.md" \
               "LICENSE" \
    )

mkdir dreamweave-build dreamweave-build/lib/ && mv resources/ dreamweave-build/ && cd dreamweave-build

for LIB in "${LIBRARIES[@]}"; do
    find /lib /usr/lib /usr/local/lib /usr/local/lib64 /lib/x86_64-linux-gnu/ ../raknet/ -name "$LIB*" -exec cp -r --preserve=links "{}" ./lib \; 2> /dev/null || true
    echo -ne "$LIB\033[0K\r"
done

for DEFAULT in "${DEFAULTS[@]}"; do
    cp ../"$DEFAULT" .
done

for BIN in "${PACKAGE_BINARIES[@]}"; do
    cp -r ../$BIN .
done

git clone https://github.com/DreamWeave-MP/CoreScripts.git server/

echo "Acquiring cjson . . ."
curl  -o server/lib/cjson.dll -L https://github.com/DreamWeave-MP/lua-cjson/releases/download/Stable-CI/cjson-MinSizeRel.dll


# Create pre-launch script
cat << 'EOF' > dreamweave-prelaunch
#!/bin/bash

ARGS="$*"
GAMEDIR="$(cd "$(dirname "$0")"; pwd -P)"
TES3MP_HOME="$HOME/.config/openmw"

# If there are config files in the home directory, load those
# Otherwise check the package/installation directory and load those
# Otherwise copy them to the home directory
if [[ "$ARGS" = 'dreamweave-server' ]]; then
    if [[ -f "$TES3MP_HOME"/dreamweave-server.cfg ]]; then
        echo -e "Loading server config from the home directory"
        LOADING_FROM_HOME=true
    elif [[ -f "$GAMEDIR"/dreamweave-server-default.cfg ]]; then
        echo -e "Loading server config from the package directory"
    else
        echo -e "Server config not found in home and package directory, trying to copy from .example"
        cp -f dreamweave-server-default.cfg.example "$TES3MP_HOME"/dreamweave-server.cfg
        LOADING_FROM_HOME=true
    fi
    if [[ $LOADING_FROM_HOME ]]; then
        if [[ -d "$TES3MP_HOME"/server ]]; then
            echo -e "Loading CoreScripts folder from the home directory"
        else
            echo -e "CoreScripts folder not found in home directory, copying from package directory"
            cp -rf "$GAMEDIR"/server/ "$TES3MP_HOME"/
            sed -i "s|home = .*|home = $TES3MP_HOME/server |g" "$TES3MP_HOME"/dreamweave-server.cfg
        fi
    fi
else
    if [[ -f $TES3MP_HOME/dreamweave-client.cfg ]]; then
        echo -e "Loading client config from the home directory"
    elif [[ -f dreamweave-client-default.cfg ]]; then
        echo -e "Loading client config from the package directory"
    else
        echo -e "Client config not found in home and package directory, trying to copy from .example"
        cp -f "$GAMEDIR"/dreamweave-client-default.cfg.example "$TES3MP_HOME"/dreamweave-client.cfg
    fi
fi
EOF

  # Create wrappers
  echo -e "\n\nCreating wrappers"
  for BINARY in "${PACKAGE_BINARIES[@]}"; do
    if [ ! -f "$BINARY" ]; then
      echo -e "Binary $BINARY not found"
    else
      WRAPPER="$BINARY"
      BINARY_RENAME="$BINARY.x86_64"
      mv "$BINARY" "$BINARY_RENAME"
      printf "#!/bin/bash\n\nWRAPPER=\"\$(basename \$0)\"\nGAMEDIR=\"\$(dirname \$0)\"\ncd \"\$GAMEDIR\"\nif test -f ./dreamweave-prelaunch; then bash ./dreamweave-prelaunch \"\$WRAPPER\"; fi\nLD_LIBRARY_PATH=\"./lib\" ./$BINARY_RENAME \"\$@\"" > "$WRAPPER"
    fi
  done
  chmod 755 *

  echo "Job complete! Making archive . . ."
  cd ..
  tar -cvf dreamweave_linux.tar dreamweave-build
