#!/bin/bash

set -eux

RELEASE="256"
URI="https://github.com/systemd/systemd/archive/refs/tags/v${RELEASE}.tar.gz"
BUILD_DIR="/tmp/build-systemd-v${RELEASE}"
INSTALLED_RELEASE="$(systemctl --version | head -n 1 | awk '{print $2}')"

if [ "$(echo -n "${INSTALLED_RELEASE}" | cut -c -3)" -ge "$(echo -n "${RELEASE}" | cut -c -3)" ]; then
  echo "Installed systemd is already at version 256 or later."
  if echo -n "${INSTALLED_RELEASE}" | grep -q "rc"; then
    if [ "$(echo -n "${RELEASE}" | wc -c)" -gt "3" ]; then
      if [ "$(echo -n "${INSTALLED_RELEASE}" | cut -c 7-)" -ge "$(echo -n "${RELEASE}" | cut -c 7-)" ]; then
        echo "Installed systemd is already at version ${RELEASE} or later."
        exit 0
      fi
    fi
  fi
fi

echo "
Installed systemd version is ${INSTALLED_RELEASE}.
Building systemd version ${RELEASE}.
"

sudo apt-get update
sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes build-dep systemd
sudo apt-get --assume-yes install python3-pip python3-venv

python3 -m venv "${BUILD_DIR}"

if [ -f "${BUILD_DIR}/bin/activate" ]; then
  source "${BUILD_DIR}/bin/activate"
else
  echo "Failed to activate virtual environment"
  exit 1
fi

if [ -x "$(which meson)" ]; then
  MESON_VERSION=$(meson --version)
  python3 -m pip install -U pip jinja2 "meson==${MESON_VERSION}" ninja
else
  python3 -m pip install -U pip jinja2 meson ninja
fi


cd "${BUILD_DIR}"
wget --no-clobber "${URI}"
tar -xzvf "v${RELEASE}.tar.gz"
cd "systemd-${RELEASE}"

sudo chmod 0755 /tmp/user/ # https://github.com/systemd/systemd/issues/33006

meson setup build
ninja -C build
meson test -C build
sudo meson install -C build/ --no-rebuild
