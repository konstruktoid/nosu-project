#!/bin/bash
#
# This script creates a polkit rule that allows users in the wheel group
# to execute commands using run0 without authentication.

set -eux

mkdir -p /etc/polkit-1/rules.d

if ! getent group wheel; then
  addgroup wheel
fi

usermod -aG wheel vagrant

echo 'polkit.addAdminRule(function(action, subject) {
  return ["unix-group:wheel"];
});

polkit.addRule(function(action, subject) {
  if(action.id == "org.freedesktop.systemd1.manage-units" &&
    subject.isInGroup("wheel") &&
    subject.user == "vagrant") {
    return polkit.Result.YES;
  }
});' | tee /etc/polkit-1/rules.d/60-run0-fast-user-auth.rules
