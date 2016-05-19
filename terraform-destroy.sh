#!/bin/bash
# vim: set ft=sh

set -e

if [ -z "$STACK_NAME" ]; then
  echo "must specify \$STACK_NAME" >&2
  exit 1
fi

if [ -z "$S3_TFSTATE_BUCKET" ]; then
  echo "must specify \$S3_TFSTATE_BUCKET" >&2
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "must specify \$AWS_ACCESS_KEY_ID" >&2
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "must specify \$AWS_SECRET_ACCESS_KEY" >&2
  exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo "must specify \$AWS_DEFAULT_REGION" >&2
  exit 1
fi

terraform remote config \
  -backend=s3 \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate"

terraform destroy \
    -refresh=true \
    -force \
    terraform-templates

