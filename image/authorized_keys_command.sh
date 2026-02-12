#!/usr/bin/env bash

set -euo pipefail

username=$1

if [[ $username == "git" ]]; then
  sed -e '/^$/d' -e 's|^|command="/usr/bin/git-shell-wrapper" |' /root/git_authorized_keys
elif [[ $username == "root" ]]; then
  cat /root/git_authorized_keys
fi
