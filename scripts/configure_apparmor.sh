#!/bin/bash
CONFIG="/etc/apparmor/parser.conf"

# shellcheck disable=SC2016
echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX apparmor=1 security=apparmor"' |\
  tee /etc/default/grub.d/99-hardening-apparmor.cfg

if ! grep -q "APPARMOR-CACHE" "$CONFIG"; then
  tee -a "$CONFIG" > /dev/null <<'EOF'

# APPARMOR-CACHE
write-cache
cache-loc /etc/apparmor/earlypolicy/
Optimize=compress-fast
# END-APPARMOR-CACHE
EOF
fi

apt install --assume-yes --no-install-recommends --update \
    apparmor apparmor-profiles apparmor-utils auditd gnupg2

systemctl enable --now apparmor auditd
