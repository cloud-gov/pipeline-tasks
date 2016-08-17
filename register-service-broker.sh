#!/bin/bash

set -e
set -u

# Authenticate
cf login -a $CF_API_URL -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORGANIZATION -s $CF_SPACE

# Get service broker URL
BROKER_URL=https://$(cf app $BROKER_NAME | grep urls: | sed 's/urls: //')

# Create or update service broker
if ! cf create-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL; then
  cf update-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL
fi

# Enable access to service plans
ARGS=()
if [ -n "$SERVICE_ORGANIZATION" ]; then ARGS+=("-o" "$SERVICE_ORGANIZATION"); fi
if [ -n "$SERVICE_PLAN" ]; then ARGS+=("-p" "$SERVICE_PLAN"); fi
for SERVICE_NAME in $(echo $SERVICE_NAMES); do
  cf enable-service-access $SERVICE_NAME "${ARGS[@]}"
done
