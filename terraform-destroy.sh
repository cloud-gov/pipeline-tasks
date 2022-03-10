#!/bin/bash
# vim: set ft=sh

set -eux

TERRAFORM="${TERRAFORM_BIN:-terraform}"

DIR="terraform-templates"

if [ -n "$TEMPLATE_SUBDIR" ]; then
  DIR="$DIR/$TEMPLATE_SUBDIR"
fi

# Hack: Disable `prevent_destroy` if requested
# See https://github.com/hashicorp/terraform/issues/3874
if [ "${PREVENT_PREVENT_DESTROY:-}" == "true" ]; then
  find terraform-templates -type f -name "*.tf" -exec sed -i 's/prevent_destroy = true/prevent_destroy = false/g' {} +
fi

${TERRAFORM} -chdir=${DIR} get \
  -update 

${TERRAFORM} -chdir=${DIR} init \
  -backend=true \
  -backend-config="encrypt=true" \
  -backend-config="bucket=${S3_TFSTATE_BUCKET}" \
  -backend-config="key=${STACK_NAME}/terraform.tfstate" 

terraform -chdir=${DIR} destroy \
  -refresh=true \
  -force

aws s3 cp "s3://${S3_TFSTATE_BUCKET}/${STACK_NAME}/terraform.tfstate" terraform-state
