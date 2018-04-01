#!/bin/bash
# vim: set ft=sh

set -eux

if [ "$TERRAFORM_ACTION" != "plan" ] && \
    [ "$TERRAFORM_ACTION" != "apply" ]; then
  echo 'must set $TERRAFORM_ACTION to "plan" or "apply"' >&2
  exit 1
fi

TERRAFORM="${TERRAFORM_BIN:-terraform}"

DIR="terraform-templates"

if [ -n "${TEMPLATE_SUBDIR:-}" ]; then
  DIR="${DIR}/${TEMPLATE_SUBDIR}"
fi

${TERRAFORM} get \
  -update \
  "${DIR}"

${TERRAFORM} init \
  -backend=true \
  -backend-config="encrypt=true" \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate" \
  "${DIR}"

if [ "${TERRAFORM_ACTION}" = "plan" ]; then
  ${TERRAFORM} "${TERRAFORM_ACTION}" \
    -refresh=true \
    -out=./terraform-state/terraform.tfplan \
    "${DIR}"

  # Write a sentinel value; pipelines can alert to slack if set using `text_file`
  # Ensure that slack notification resource detects text file
  touch ./terraform-state/message.txt
  if ! ${TERRAFORM} show ./terraform-state/terraform.tfplan | grep 'This plan does nothing.' ; then
    echo "sentinel" > ./terraform-state/message.txt
  fi
else
  # run apply twice to work around bugs like this
  # https://github.com/hashicorp/terraform/issues/7235
  ${TERRAFORM} "${TERRAFORM_ACTION}" \
    -refresh=true \
    -auto-approve \
    "${DIR}"
  ${TERRAFORM} "${TERRAFORM_ACTION}" \
    -refresh=true \
    -auto-approve \
    "${DIR}"
  aws s3 cp "s3://${S3_TFSTATE_BUCKET}/${STACK_NAME}/terraform.tfstate" terraform-state
fi
