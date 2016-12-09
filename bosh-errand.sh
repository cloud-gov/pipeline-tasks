#!/bin/bash
# vim: set ft=sh

set -e -u

#
# Run the errand for the appropriate deployment
#

# Hack: Add trailing newline to skip OTP prompt
bosh-cli -n -e "${BOSH_TARGET}" --ca-cert "${BOSH_CACERT}" alias-env env
bosh-cli -e env log-in <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}

EOF
bosh-cli -n -e env -d "${BOSH_DEPLOYMENT_NAME}" run-errand "${BOSH_ERRAND}"
