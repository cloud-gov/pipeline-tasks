#!/bin/bash

set -e
set -u

# Authenticate
cf login -a $CF_API_URL -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORGANIZATION -s $CF_SPACE

# Get service broker URL
BROKER_URL=https://$(cf app $BROKER_NAME | grep routes: | awk '{print $2}')

# Create or update service broker
if ! cf create-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL $CF_FLAGS; then
  cf update-service-broker $BROKER_NAME $AUTH_USER $AUTH_PASS $BROKER_URL
fi

set -x

if [ -n "${SERVICE_ORGANIZATION:-}" ] && [ -n "${SERVICE_ORGANIZATION_BLACKLIST:-}" ]; then
  echo "You may set SERVICE_ORGANIZATION or SERVICE_ORGANIZATION_BLACKLIST but not both"
  exit 1;
fi

# Enable access to service plans
# Services should be a set of "$name" or "$name:$plan" values, such as
# "redis28-multinode mongodb30-multinode:persistent"
for SERVICE in $(echo "$SERVICES"); do
  SERVICE_NAME=$(echo "${SERVICE}:" | cut -d':' -f1)
  SERVICE_PLAN=$(echo "${SERVICE}:" | cut -d':' -f2)
  ARGS=("${SERVICE_NAME}")
  if [ -n "${SERVICE_PLAN}" ]; then ARGS+=("-p" "${SERVICE_PLAN}"); fi

  # Must disable services prior to enabling, otherwise enable will fail if already exists
  # https://github.com/cloudfoundry/cli/issues/939
  cf disable-service-access "${ARGS[@]}"

  # if we have a blacklist, then we enable for all organizations EXCEPT those
  # since CF doesn't suport this; enumerate all organizations, and filter out those on the blacklist
  # and enable for each remaining org
  if [ -n "${SERVICE_ORGANIZATION_BLACKLIST:-}" ]; then

    for org in `cf orgs | tail -n +4 | grep -Fvxf <(echo $SERVICE_ORGANIZATION_BLACKLIST | tr " " "\n")`; do
      cf enable-service-access "${ARGS[@]}" -o ${org}
    done

  else
    # if we don't have a blacklist, but do have a whitelist, then iterate over that list
    # and enable  for each of those orgs
    if [ -n "${SERVICE_ORGANIZATION:-}" ]; then

      for org in `echo ${SERVICE_ORGANIZATION} | tr " " "\n"`; do
        cf enable-service-access "${ARGS[@]}" -o ${org}
      done

    # if we don't have any kind of list, enable for all orgs
    else

      cf enable-service-access "${ARGS[@]}"

    fi
  fi
done
