#!/bin/bash

set -eux

RELEASE="latest" # head, latest or version number
INSTALLED_RELEASE="$(pkaction --version | awk '{print $NF}')"
BUILD_DIR="/tmp/build-polkit-${RELEASE}"

if [ "${RELEASE}" == "head" ]; then
  URI="https://github.com/polkit-org/polkit/archive/refs/heads/main.zip"
else
    RELEASE=$(curl -fsSL https://api.github.com/repos/polkit-org/polkit/releases/latest | jq -r '.["tag_name"]')
fi

NUM_RELEASE="$(echo -n "${RELEASE}" | cut -c 1-)"
URI="https://github.com/polkit-org/polkit/archive/refs/tags/${RELEASE}.tar.gz"

echo "
Installed polkit is ${INSTALLED_RELEASE}.
Building polkit version ${RELEASE}.
"

sudo sed -i s/'^Types: deb$/Types: deb deb-src/g' /etc/apt/sources.list.d/ubuntu.sources

sudo apt-get upgrade --assume-yes --update
sudo apt-get build-dep --assume-yes polkitd
sudo apt-get install --assume-yes --no-install-recommends unzip

curl -LsSf https://astral.sh/uv/install.sh | sh
source "${HOME}/.local/bin/env"
uv venv "${BUILD_DIR}"

if [ -f "${BUILD_DIR}/bin/activate" ]; then
  source "${BUILD_DIR}/bin/activate"
else
  echo "Failed to activate virtual environment"
  exit 1
fi

uv pip install -U pip jinja2 meson ninja


cd "${BUILD_DIR}" || exit 1
wget --no-clobber "${URI}"

if [ "${RELEASE}" == "head" ]; then
  unzip main.zip
  cd "polkit-main" || exit 1
else
  tar -xzvf "${RELEASE}.tar.gz"
  cd "polkit-${NUM_RELEASE}" || exit 1
fi

meson setup build
ninja -C build
meson test -C build
sudo meson install -C build/ --no-rebuild
