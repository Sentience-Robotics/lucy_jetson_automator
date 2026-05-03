#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec ansible-playbook \
  -i "${ROOT}/ansible/inventory/vps-bootstrap/hosts.yml" \
  "${ROOT}/ansible/playbooks/vps-bootstrap.yml" \
  "$@"
