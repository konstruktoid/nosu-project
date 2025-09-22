#!/bin/bash

set -eux

RELEASE="head" # head, latest or version number
INSTALLED_RELEASE="$(systemctl --version | head -n 1 | awk '{print $2}')"
BUILD_DIR="/tmp/build-systemd-${RELEASE}"

if [ "${RELEASE}" == "head" ]; then
  URI="https://github.com/systemd/systemd/archive/refs/heads/main.zip"
else
  if [ "${RELEASE}" == "latest" ]; then
    RELEASE=$(curl -fsSL https://api.github.com/repos/systemd/systemd/releases/latest | jq -r '.["tag_name"]')
  fi

  NUM_RELEASE="$(echo -n "${RELEASE}" | cut -c 2-)"
  URI="https://github.com/systemd/systemd/archive/refs/tags/${RELEASE}.tar.gz"

  if [ "$(echo -n "${INSTALLED_RELEASE}" | cut -c -3)" -ge "$(echo -n "${RELEASE}" | cut -c 2-4)" ]; then
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
fi

echo "
Installed systemd version is ${INSTALLED_RELEASE}.
Building systemd version ${RELEASE}.
"

sudo sed -i s/'^Types: deb$/Types: deb deb-src/g' /etc/apt/sources.list.d/ubuntu.sources

sudo apt-get update
sudo apt-get --assume-yes build-dep systemd
sudo apt-get --assume-yes install unzip --no-install-recommends

curl -LsSf https://astral.sh/uv/install.sh | sh
source "${HOME}/.local/bin/env"
uv venv -p3.12 "${BUILD_DIR}"

if [ -f "${BUILD_DIR}/bin/activate" ]; then
  source "${BUILD_DIR}/bin/activate"
else
  echo "Failed to activate virtual environment"
  exit 1
fi

if [ -x "$(which meson)" ]; then
  MESON_VERSION=$(meson --version)
  uv pip install -U pip jinja2 "meson==${MESON_VERSION}" ninja
else
  uv pip install -U pip jinja2 meson ninja
fi


cd "${BUILD_DIR}" || exit 1
wget --no-clobber "${URI}"

if [ "${RELEASE}" == "head" ]; then
  unzip main.zip
  cd "systemd-main" || exit 1
else
  tar -xzvf "${RELEASE}.tar.gz"
  cd "systemd-${NUM_RELEASE}" || exit 1
fi

if [ -d "/tmp/user" ]; then
  sudo chmod 0755 /tmp/user/ # https://github.com/systemd/systemd/issues/33006
fi

meson setup build
ninja -C build
meson test -C build
sudo meson install -C build/ --no-rebuild
