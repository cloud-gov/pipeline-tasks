#!/bin/bash

set -e -x

if [ -z "$BOSH_TARGET" ]; then
  echo "must specify \$BOSH_TARGET" >&2
  exit 1
fi

if [ -z "$BOSH_USERNAME" ]; then
  echo "must specify \$BOSH_USERNAME" >&2
  exit 1
fi

if [ -z "$BOSH_PASSWORD" ]; then
  echo "must specify \$BOSH_PASSWORD" >&2
  exit 1
fi

if [ -n "$BOSH_CERT" ]; then
  bosh --ca-cert certificate/$BOSH_CERT -n target $BOSH_TARGET
else
  bosh -n target $BOSH_TARGET
fi

bosh login <<EOF 1>/dev/null
$BOSH_USERNAME
$BOSH_PASSWORD
EOF

for r in release/*.tgz; do
  bosh upload release $r
done
