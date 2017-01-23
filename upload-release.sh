#!/bin/bash

set -e -u

BOSH_CERT="${BOSH_CERT:-}"
if [ -n "${BOSH_CERT}" ]; then
  bosh-cli -n -e "${BOSH_TARGET}" --ca-cert "certificate/${BOSH_CERT}" alias-env env
else
  bosh-cli -n -e "${BOSH_TARGET}" alias-env env
fi

if [ -n "${BOSH_USERNAME:-}" ]; then
  # Hack: Add trailing newline to skip OTP prompt
  bosh-cli -e env log-in <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}

EOF
fi

for r in release/*.tgz; do
  bosh-cli -e env upload-release "${r}"
done
