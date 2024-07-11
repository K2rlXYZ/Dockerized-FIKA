#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

START_TIMEOUT="${START_TIMEOUT:=40s}"  # Set to the maximum time in seconds to wait for the server to start during first boot
HEADLESS="${HEADLESS:-}"              # Set to "true" to run the server immediately after first-time config
FORCE="${FORCE:-}"                    # Set to "true" to force update the server files (i.e. to upgrade, re-configure, etc.)
HOST_IP="${HOST_IP:=$(curl -s4 ipv4.icanhazip.com)}"

echo "Starting up FIKA (Docker)"
echo "Built for SPT $SPT_BRANCH"
echo -e "Built for FIKA $FIKA_SERVER_BRANCH\n"

if [ ! -e "/opt/server/version" ] || [ ! -z "$FORCE" ]; then
  if [ -d "/opt/fika" ]; then
    echo "Performing first-time setup... please wait."

    start=$(date +%s)

    cp -r /opt/fika/* /opt/server/
    rm -r /opt/fika
    cd /opt/server
    chown $(id -u):$(id -g) ./* -Rf
    sed -i 's/\"ip\": \"127.0.0.1\"/\"ip\": \"0.0.0.0\"/g' ./SPT_Data/Server/configs/http.json
    sed -i "s/\"backendIp\": \"127.0.0.1\"/\"backendIp\": \"$HOST_IP\"/g" ./SPT_Data/Server/configs/http.json

    end=$(date +%s)

    echo "Copied SPT & FIKA files to your machine in $(($end-$start)) second(s)."
    echo "Booting up the server for $START_TIMEOUT to generate all the required files... please wait."

    NODE_CHANNEL_FD= timeout "$START_TIMEOUT" ./SPT.Server.exe </dev/null >/dev/null 2>&1 || true

    echo "$FIKA_SERVER_BRANCH" > /opt/server/version
    echo "Version $FIKA_SERVER_BRANCH is now set in ./server/version"
    echo -e "FIKA (Docker) setup is now complete!\n"

    if [ -z "$HEADLESS" ]; then
      echo "You can configure and start your container."
      exit 0
    else
      echo "Headless mode requested, starting the server immediately..."
    fi
  fi
else
  DETECTED_VERSION=$(cat /opt/server/version)
  echo "Detected $DETECTED_VERSION in ./server/version, use -e FORCE=true if updating..."
fi

exec "$@"
