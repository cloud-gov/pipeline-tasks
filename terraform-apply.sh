#!/bin/bash
# vim: set ft=sh

set -ex

if [ -z "$STACK_NAME" ]; then
  echo "must specify \$STACK_NAME" >&2
  exit 1
fi

if [ -z "$S3_TFSTATE_BUCKET" ]; then
  echo "must specify \$S3_TFSTATE_BUCKET" >&2
  exit 1
fi

if [ "$TERRAFORM_ACTION" != "plan" ] && \
    [ "$TERRAFORM_ACTION" != "apply" ]; then
  echo 'must set $TERRAFORM_ACTION to "plan" or "apply"' >&2
  exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo "must specify \$AWS_DEFAULT_REGION" >&2
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS credentials not found in params; attempting to use Instance Profile." >&2
fi

TERRAFORM="${TERRAFORM_BIN:-terraform}"

DIR="terraform-templates"

if [ -n "$TEMPLATE_SUBDIR" ]; then
  DIR="$DIR/$TEMPLATE_SUBDIR"
fi

${TERRAFORM} remote config \
  -backend=s3 \
  -backend-config="encrypt=true" \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate" || \
${TERRAFORM} init \
  -backend=true \
  -backend-config="encrypt=true" \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate" \
  ${DIR}

${TERRAFORM} get \
  -update \
  $DIR

if [ "${TERRAFORM_ACTION}" = "plan" ]; then
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    -out="${PLAN_FILE:-}" \
    $DIR
else
  # run apply twice to work around bugs like this
  # https://github.com/hashicorp/terraform/issues/7235
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    $DIR
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    $DIR
fi

cp .terraform/terraform* terraform-state
