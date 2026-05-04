#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ROOT}/.env"
# Run from ansible/ so ansible.cfg (roles_path=roles → ansible/roles/) is loaded.
ANSIBLE_DIR="${ROOT}/ansible"
REMOTE_INV=""

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
  fi
}

cleanup() {
  if [[ -n "${REMOTE_INV:-}" && -f "${REMOTE_INV}" ]]; then
    rm -f "${REMOTE_INV}"
  fi
}

write_remote_inventory() {
  local keyline="" portline="" keypath=""
  if [[ -n "${VPS_SSH_PRIVATE_KEY_FILE:-}" ]]; then
    keypath="${VPS_SSH_PRIVATE_KEY_FILE/#\~/${HOME}}"
    if [[ "${keypath}" != /* ]]; then
      keypath="${ROOT}/${keypath}"
    fi
    keyline=" ansible_ssh_private_key_file=${keypath}"
  fi
  if [[ -n "${VPS_SSH_PORT:-}" ]]; then
    portline=" ansible_port=${VPS_SSH_PORT}"
  fi
  REMOTE_INV="$(mktemp "${TMPDIR:-/tmp}/lucy-vps-inv.XXXXXX")"
  # Temp inventory is under /tmp — ansible/group_vars/ is not loaded; pin interpreter on the host line.
  local inv_vars=" ansible_python_interpreter=/usr/bin/python3"
  {
    echo "[vps_bootstrap]"
    echo "remote-vps ansible_host=${VPS_SSH_HOST} ansible_user=${VPS_SSH_USER}${portline}${keyline}${inv_vars}"
  } >"${REMOTE_INV}"
}

load_env
trap cleanup EXIT

if [[ -z "${VPS_SSH_HOST:-}" ]] || [[ -z "${VPS_SSH_USER:-}" ]]; then
  echo "Error: VPS_SSH_HOST and VPS_SSH_USER must be set in .env (remote-only bootstrap over SSH)." >&2
  exit 1
fi

write_remote_inventory
(
  cd "${ANSIBLE_DIR}"
  ansible-playbook -i "${REMOTE_INV}" "playbooks/vps-bootstrap.yml" "$@"
)
rc=$?
trap - EXIT
cleanup
exit "${rc}"
