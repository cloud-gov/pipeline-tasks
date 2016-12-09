#!/bin/bash

set -e -u

# Hack: Add trailing newline to skip OTP prompt

BOSH_CERT="${BOSH_CERT:-}"
if [ -n "${BOSH_CERT}" ]; then
  bosh-cli -n -e "${BOSH_TARGET}" --ca-cert "certificate/${BOSH_CERT}" alias-env env
else
  bosh-cli -n -e "${BOSH_TARGET}" alias-env env
fi
bosh-cli -e env log-in <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}

EOF

for r in release/*.tgz; do
  bosh-cli -e env upload-release "${r}"
done
