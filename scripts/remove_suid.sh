#!/bin/bash

set -u
fix_perms="0755"

find / -perm "/4000" -type f -exec stat -c "%U %G %a %n" {} \; 2>/dev/null |\
  while read -r user group perms file; do
    fix_perms="0$(echo "${perms}" | cut -c 2-4)"
    echo "dpkg-statoverride --update --force-all --add \"${user}\" \"${group}\" \"${fix_perms}\" \"${file}\""
done
