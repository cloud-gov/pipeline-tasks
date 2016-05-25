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

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo "must specify \$AWS_DEFAULT_REGION" >&2
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS credentials not found in params; attempting to use Instance Profile." >&2
fi

DIR="terraform-templates"

if [ -n "$TEMPLATE_SUBDIR" ]; then
  DIR="$DIR/$TEMPLATE_SUBDIR"
fi


terraform remote config \
  -backend=s3 \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate"

terraform get \
  -update \
  $DIR

terraform destroy \
  -refresh=true \
  -force \
  $DIR

cp .terraform/terraform* terraform-state
