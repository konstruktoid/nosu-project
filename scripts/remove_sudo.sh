#!/bin/bash

set -eux

# shellcheck disable=SC2289
echo'Package: sudo
Pin: release *
Pin-Priority: -10

Package: sudo-*
Pin: release *
Pin-Priority: -10

Package: *-sudo
Pin: release *
Pin-Priority: -10' | run0 tee /etc/apt/preferences.d/run0-no-sudo

# shellcheck disable=SC2035
run0 --setenv=SUDO_FORCE_REMOVE=yes apt-get --assume-yes purge *-sudo sudo-* sudo

run0 rm -vrf /etc/sudoers.d

run0 ln -s "$(which run0)" /usr/bin/sudo
