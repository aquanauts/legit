#!/usr/bin/env bash

set -euo pipefail

username=$1

if [[ $username == "git" ]]; then
  while read -r line; do
    if [[ -n "$line" ]]; then
      echo "command=\"/usr/bin/git-shell-wrapper\" $line"
    fi
  done < /root/git_authorized_keys
fi
