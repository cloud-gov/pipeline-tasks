#!/bin/bash
# vim: set ft=sh

set -eux

if [ "$TERRAFORM_ACTION" != "plan" ] && \
    [ "$TERRAFORM_ACTION" != "apply" ]; then
  echo 'must set $TERRAFORM_ACTION to "plan" or "apply"' >&2
  exit 1
fi

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  echo "AWS credentials not found in params; attempting to use Instance Profile." >&2
fi

TERRAFORM="${TERRAFORM_BIN:-terraform}"

DIR="terraform-templates"

if [ -n "${TEMPLATE_SUBDIR:-}" ]; then
  DIR="${DIR}/${TEMPLATE_SUBDIR}"
fi

${TERRAFORM} get \
  -update \
  ${DIR}

${TERRAFORM} init \
  -backend=true \
  -backend-config="encrypt=true" \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate" \
  ${DIR}

if [ "${TERRAFORM_ACTION}" = "plan" ]; then
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    -out=./terraform-state/terraform.tfplan \
    ${DIR}

  set +e
  ${TERRAFORM} show ./terraform-state/terraform.tfplan \
    | grep -v "This plan does nothing." \
    > ./terraform-state/message.txt
  set -e
else
  # run apply twice to work around bugs like this
  # https://github.com/hashicorp/terraform/issues/7235
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    ${DIR}
  ${TERRAFORM} $TERRAFORM_ACTION \
    -refresh=true \
    ${DIR}
  aws s3 cp "s3://${S3_TFSTATE_BUCKET}/${STACK_NAME}/terraform.tfstate" terraform-state
fi
