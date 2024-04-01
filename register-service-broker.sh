#!/usr/bin/env bash

#############
# Register a service broker with CF
# environment config
#    CF_API_URL       API to auth against
#    CF_USERNAME      User to auth as. Needs to have cf admin permissions
#    CF_PASSWORD      Password for user
#    CF_SPACE         Space to target - if the broker is a CF app in $CF_SPACE and $BROKER_URL is unset, we can discover the broker's url this way
#    CF_ORGANIZATION  org to target - if the broker is a CF app in $CF_ORGANIZATION and $BROKER_URL is unset, we can discover the broker's url this way
#    BROKER_NAME      Name to register broker as, should also match the broker's app name to leverage BROKER_URL discovery
#    BROKER_URL       URL where CAPI can reach the service broker
#    AUTH_USER        Username for CAPI to talk to the broker
#    AUTH_PASS        Password for CAPI to talk to the broker
#
#############

# Authenticate
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")
cf target -o "${CF_ORGANIZATION}" -s "${CF_SPACE}"

# Get service broker URL
if [ -z "${BROKER_URL:-}" ]; then
  BROKER_URL=https://$(cf app "${BROKER_NAME}" | grep routes: | awk '{print $2}')
fi

# Create or update service broker
if ! cf create-service-broker "${BROKER_NAME}" "${AUTH_USER}" "${AUTH_PASS}" "${BROKER_URL}"; then
  cf update-service-broker "${BROKER_NAME}" "${AUTH_USER}" "${AUTH_PASS}" "${BROKER_URL}"
fi
