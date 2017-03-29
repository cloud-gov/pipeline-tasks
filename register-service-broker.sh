#!/bin/bash

set -e
set -u

# Authenticate
cf login -a $CF_API_URL -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORGANIZATION -s $CF_SPACE

# Get service broker URL
BROKER_URL=https://$(cf app $BROKER_NAME | grep urls: | sed 's/urls: //')

# Create or update service broker
if ! cf create-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL $CF_FLAGS; then
  cf update-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL
fi

set -x

# Enable access to service plans
# Services should be a set of "$name" or "$name:$plan" values, such as
# "redis28-multinode mongodb30-multinode:persistent"
for SERVICE in $(echo "$SERVICES"); do
  SERVICE_NAME=$(echo "${SERVICE}:" | cut -d':' -f1)
  SERVICE_PLAN=$(echo "${SERVICE}:" | cut -d':' -f2)
  ARGS=("${SERVICE_NAME}")
  if [ -n "${SERVICE_ORGANIZATION:-}" ]; then ARGS+=("-o" "${SERVICE_ORGANIZATION}"); fi
  if [ -n "${SERVICE_PLAN}" ]; then ARGS+=("-p" "${SERVICE_PLAN}"); fi
  # Must disable services prior to enabling, otherwise enable will fail if already exists
  # https://github.com/cloudfoundry/cli/issues/939
  cf disable-service-access "${ARGS[@]}"

  # If SERVICE_ORGANIZATION_BLACKLIST, then expect service to be singular
  if [ -n "${SERVICE_ORGANIZATION_BLACKLIST:-}" ]; then
    CF_ORGS_OUTPUT="$(cf orgs)"
    org_array=()
    while read -r org_array_line; do
      if [ ${org_array_line} != ${SERVICE_ORGANIZATION_BLACKLIST} ]; then
        org_array+=("$org_array_line")
      fi
    done <<< "$cf_orgs_output"
    org_array = ("${org_array[@]:3}")

    for org in org_array; do
      cf enable-service-access ${SERVICE_NAME} -o ${org}
    done
  else
    cf enable-service-access "${ARGS[@]}"
  fi
done
