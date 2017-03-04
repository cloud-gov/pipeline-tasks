#!/bin/bash
# vim: set ft=sh

set -e -u

#
# Run the errand for the appropriate deployment
#

bosh-cli -n -e "${BOSH_TARGET}" --ca-cert "${BOSH_CACERT}" alias-env env

if [ -n "${BOSH_USERNAME:-}" ]; then
  # Hack: Add trailing newline to skip OTP prompt
  bosh-cli -e env log-in <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}

EOF
fi

args=("${BOSH_ERRAND}")
args+=(${BOSH_FLAGS:-})
bosh-cli -n -e env -d "${BOSH_DEPLOYMENT_NAME}" run-errand "${args[@]}"
