#!/bin/bash
# vim: set ft=sh

set -e

if [ -z "$STATE_FILE" ]; then
  echo "must specify \$STATE_FILE" >&2
  exit 1
fi

if [ -z "$TF_VAR_ACCESS_KEY_ID" ]; then
  echo "must specify \$TF_VAR_ACCESS_KEY_ID" >&2
  exit 1
fi

if [ -z "$TF_VAR_SECRET_ACCESS_KEY" ]; then
  echo "must specify \$TF_VAR_SECRET_ACCESS_KEY" >&2
  exit 1
fi

if [ -z "$TF_VAR_DEFAULT_REGION" ]; then
  echo "must specify \$TF_VAR_DEFAULT_REGION" >&2
  exit 1
fi

terraform apply \
    -refresh=true \
    -state=terraform-state/${STATE_FILE} \
    -state-out=terraform-result/${STATE_FILE} \
    terraform-templates

