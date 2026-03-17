#!/bin/bash

set -eux

# shellcheck disable=SC2289
echo 'Package: sudo
Pin: release *
Pin-Priority: -10

Package: sudo-*
Pin: release *
Pin-Priority: -10

Package: *-sudo
Pin: release *
Pin-Priority: -10' | tee /etc/apt/preferences.d/run0-no-sudo

# shellcheck disable=SC2035
export SUDO_FORCE_REMOVE=yes
apt-get --assume-yes purge *-sudo sudo-* sudo
rm -vrf /etc/sudoers.d
ln -s "$(which run0)" /usr/bin/sudo

if command -v pkexec &>/dev/null; then
  chmod 0755 "$(which pkexec)"
  dpkg-statoverride --update --force-all --add root root 0755 "$(which pkexec)"
fi
