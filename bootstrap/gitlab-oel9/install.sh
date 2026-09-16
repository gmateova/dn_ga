#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root (sudo -E)." >&2
  exit 1
fi

: "${GITLAB_EXTERNAL_URL:?Set GITLAB_EXTERNAL_URL}"

GITLAB_PACKAGE="${GITLAB_PACKAGE:-gitlab-ee}"
GITLAB_REPO_SCRIPT_URL="${GITLAB_REPO_SCRIPT_URL:-https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh}"

# Optional outbound proxy for TEST/restricted networks.
# Configure these as protected GitLab CI/CD variables or export them before
# running the bootstrap. Do not commit proxy credentials to this repository.
HTTP_PROXY="${HTTP_PROXY:-${http_proxy:-}}"
HTTPS_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY}}}"
NO_PROXY="${NO_PROXY:-${no_proxy:-localhost,127.0.0.1,::1}}"

export HTTP_PROXY HTTPS_PROXY NO_PROXY
export http_proxy="${HTTP_PROXY}" https_proxy="${HTTPS_PROXY}" no_proxy="${NO_PROXY}"

configure_proxy() {
  if [[ -z "${HTTP_PROXY}" && -z "${HTTPS_PROXY}" ]]; then
    echo "No outbound proxy configured."
    return
  fi

  echo "Outbound proxy enabled for GitLab bootstrap."
  echo "NO_PROXY=${NO_PROXY}"

  mkdir -p /etc/systemd/system/gitlab-runsvdir.service.d
  cat > /etc/systemd/system/gitlab-runsvdir.service.d/proxy.conf <<EOF
[Service]
Environment="http_proxy=${HTTP_PROXY}"
Environment="https_proxy=${HTTPS_PROXY}"
Environment="no_proxy=${NO_PROXY}"
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=${NO_PROXY}"
EOF

  systemctl daemon-reload
}

install_prerequisites() {
  dnf install -y curl ca-certificates openssh-server policycoreutils-python-utils
  systemctl enable --now sshd
}

configure_repository() {
  if ! dnf repolist --enabled | grep -qE '^gitlab_gitlab-(ee|ce)'; then
    curl --fail --location --show-error "${GITLAB_REPO_SCRIPT_URL}" | bash
  fi
}

install_gitlab() {
  if rpm -q "${GITLAB_PACKAGE}" >/dev/null 2>&1; then
    echo "${GITLAB_PACKAGE} already installed; skipping package installation."
    return
  fi

  if [[ -n "${GITLAB_INITIAL_ROOT_PASSWORD:-}" ]]; then
    EXTERNAL_URL="${GITLAB_EXTERNAL_URL}" \
    GITLAB_ROOT_PASSWORD="${GITLAB_INITIAL_ROOT_PASSWORD}" \
      dnf install -y "${GITLAB_PACKAGE}"
  else
    EXTERNAL_URL="${GITLAB_EXTERNAL_URL}" dnf install -y "${GITLAB_PACKAGE}"
  fi
}

reconcile_config() {
  local config=/etc/gitlab/gitlab.rb
  [[ -f "${config}" ]] || touch "${config}"

  # Keep the bootstrap deterministic without overwriting unrelated admin config.
  if grep -q '^external_url ' "${config}"; then
    sed -i "s|^external_url .*|external_url '${GITLAB_EXTERNAL_URL}'|" "${config}"
  else
    printf "\nexternal_url '%s'\n" "${GITLAB_EXTERNAL_URL}" >> "${config}"
  fi

  gitlab-ctl reconfigure
  gitlab-ctl restart
}

smoke_test() {
  gitlab-ctl status
  curl --fail --silent --show-error --max-time 10 \
    --noproxy "${GITLAB_HEALTH_NO_PROXY:-*}" \
    "${GITLAB_EXTERNAL_URL%/}/-/health" >/dev/null
  echo "GitLab health endpoint OK: ${GITLAB_EXTERNAL_URL%/}/-/health"
}

configure_proxy
install_prerequisites
configure_repository
install_gitlab
reconcile_config
smoke_test
