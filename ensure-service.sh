#!/bin/bash

set -eux

check_service() {
  instance="$1"
  timeout="${2:-300}"
  elapsed=0
  until [ "${elapsed}" -gt "${timeout}" ]; do
    status=$(cf service "${instance}")
    if echo "${status}" | grep "create succeeded"; then
      return 0
    elif echo "${status}" | grep "create failed"; then
      return 1
    fi
    let elapsed+=5
    sleep 5
  done
  return 1
}

# Authenticate
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")
cf target -o "${CF_ORGANIZATION}" -s "${CF_SPACE}"

if ! cf service "${INSTANCE_NAME}"; then
  cf create-service "${SERVICE_NAME}" "${PLAN_NAME}" "${INSTANCE_NAME}"
fi

check_service "${INSTANCE_NAME}" "${TIMEOUT}"
