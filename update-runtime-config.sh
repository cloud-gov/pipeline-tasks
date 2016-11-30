#!/bin/bash

set -e
set -u

bosh-cli -n -e ${BOSH_ENV} --ca-cert ${BOSH_CACERT} alias-env env
bosh-cli -e env log-in <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}
EOF

bosh-cli -e env releases --json > releases.json

# TODO: Don't depend on bosh / jq sort order
releases=$(cat releases.json | jq -r '.Tables | .[].Rows | map(.[0]) | unique | .[]')
for release in $releases; do
  filter=".Tables"
  filter="$filter | .[].Rows"
  filter="$filter | map(select(.[0] == \"${release}\") | .[1] | sub(\"\\\\*\"; \"\")) | .[0]"
  version=$(cat releases.json | jq -r "${filter}")
  declare "release_${release//-/_}"=${version}
done

spruce merge manifests/runtime-config.yml > runtime-config-merged.yml

bosh-cli -e env update-runtime-config runtime-config-merged.yml
