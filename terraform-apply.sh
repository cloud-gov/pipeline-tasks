#!/bin/bash
# vim: set ft=sh

set -eux

if [ "$TERRAFORM_ACTION" != "plan" ] && \
    [ "$TERRAFORM_ACTION" != "apply" ]; then
  echo 'must set $TERRAFORM_ACTION to "plan" or "apply"' >&2
  exit 1
fi

TERRAFORM="${TERRAFORM_BIN:-terraform}"
BASE="$(pwd)"

DIR="terraform-templates"

set +x
# unset TF_VARs that are empty strings
for tfvar in "${!TF_VAR_@}"; do
	if [[ -z "${!tfvar}" ]]; then
		unset ${tfvar}
	fi
done
set -x

if [ -n "${TEMPLATE_SUBDIR:-}" ]; then
  DIR="${DIR}/${TEMPLATE_SUBDIR}"
fi

${TERRAFORM} -chdir=${DIR} get \
  -update 

init_args=(
  "-backend=true"
  "-backend-config=encrypt=true"
  "-backend-config=bucket=${S3_TFSTATE_BUCKET}"
  "-backend-config=key=${STACK_NAME}/terraform.tfstate"
)
set +x
if [ -n "${TF_VAR_aws_region:-}" ]; then
  init_args+=("-backend-config=region=${TF_VAR_aws_region}")
fi
if [ -n "${TF_VAR_aws_access_key:-}" ]; then
  init_args+=("-backend-config=access_key=${TF_VAR_aws_access_key}")
fi
if [ -n "${TF_VAR_aws_secret_key:-}" ]; then
  init_args+=("-backend-config=secret_key=${TF_VAR_aws_secret_key}")
fi

${TERRAFORM} -chdir="${DIR}" init \
  "${init_args[@]}" 
set -x

if [ "${TERRAFORM_ACTION}" = "plan" ]; then
  ${TERRAFORM} -chdir="${DIR}" "${TERRAFORM_ACTION}" \
    -refresh=true \
    -input=false \
    -out=${BASE}/terraform-state/terraform.tfplan \
    > ${BASE}/terraform-state/terraform-plan-output.txt
  
  cat ${BASE}/terraform-state/terraform-plan-output.txt

  # Write a sentinel value; pipelines can alert to slack if set using `text_file`
  # Ensure that slack notification resource detects text file
  touch ${BASE}/terraform-state/message.txt
  if ! cat ${BASE}/terraform-state/terraform-plan-output.txt | grep 'No changes.' ; then
    echo "sentinel" > ${BASE}/terraform-state/message.txt
  fi
else
  # run apply twice to work around bugs like this
  # https://github.com/hashicorp/terraform/issues/7235
  ${TERRAFORM} -chdir="${DIR}" "${TERRAFORM_ACTION}" \
    -refresh=true \
    -input=false \
    -auto-approve
  ${TERRAFORM} -chdir="${DIR}" "${TERRAFORM_ACTION}" \
    -refresh=true \
    -input=false \
    -auto-approve

  if [ -n "${TF_VAR_aws_region:-}" ]; then
    export AWS_DEFAULT_REGION="${TF_VAR_aws_region}"
  fi
  if [ -n "${TF_VAR_aws_access_key:-}" ]; then
    export AWS_ACCESS_KEY_ID="${TF_VAR_aws_access_key}"
  fi
  if [ -n "${TF_VAR_aws_secret_key:-}" ]; then
    export AWS_SECRET_ACCESS_KEY="${TF_VAR_aws_secret_key}"
  fi
  aws s3 cp "s3://${S3_TFSTATE_BUCKET}/${STACK_NAME}/terraform.tfstate" terraform-state
fi
