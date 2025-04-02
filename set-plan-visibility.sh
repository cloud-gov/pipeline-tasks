#!/bin/bash

#############
# Make plans available for a service broker
# cli flags:
#    -s    enable for all orgs EXCEPT sandbox and smoke tests
#    -o    enable for ONLY sandbox and smoke tests orgs
# environment config
#    CF_API_URL                       API to auth against
#    CF_USERNAME                      User to auth as. Needs to have cf admin permissions
#    CF_PASSWORD                      Password for user
#    CF_SPACE                         Space to target when authenticating - probably doesn't matter?
#    CF_ORGANIZATION                  Org to target when authenticating - probably doesn't matter?
#    SERVICES                         Set of "$name" or "$name:$plan" values, such as "fooservice barservice:bazplan barservice:quuxplan"
#    BROKER_NAME                      Registered name of the broker
#    SERVICE_ORGANIZATION             Organizations that should have access to the plan, in the form "org1 org2 org3"
#    SERVICE_ORGANIZATION_DENYLIST   Organizations that should not have access to the plan, in the form "org1 org2 org3"
#    Only one of [`SERVICE_ORGANIZATION`, `SERVICE_ORGANIZATION_BLACKLIST`, `-s`] may be specified
#
#############

set -eux

# Authenticate
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")
cf target -o "${CF_ORGANIZATION}" -s "${CF_SPACE}"

if [ -n "${SERVICE_ORGANIZATION_BLACKLIST:-}" ]; then
  echo "Use of SERVICE_ORGANIZATION_BLACKLIST is deprecated - use SERVICE_ORGANIZATION_DENYLIST instead" >&2
  : "${SERVICE_ORGANIZATION_DENYLIST:${SERVICE_ORGANIZATION_BLACKLIST}}"
fi


while getopts ":so" opt; do
  case $opt in
    s)
      # Set plan visibility to EXCLUDE sandboxes if -s flag is set
      ORGLIST=""
      for org in $(cf orgs | grep 'sandbox\|SMOKE\|CATS'); do
        ORGLIST+=${org}" "
      done
      export SERVICE_ORGANIZATION_DENYLIST=${ORGLIST}
      ;;
    o)
      # Set plan visibility to ONLY sandboxes if -o flag is set
      ORGLIST=""
      for org in $(cf orgs | grep 'sandbox\|SMOKE\|CATS'); do
        ORGLIST+=${org}" "
      done
      export SERVICE_ORGANIZATION=${ORGLIST}
      ;;      
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done



if [ -n "${SERVICE_ORGANIZATION:-}" ] && [ -n "${SERVICE_ORGANIZATION_DENYLIST:-}" ]; then
  echo "You may set SERVICE_ORGANIZATION or SERVICE_ORGANIZATION_DENYLIST but not both"
  exit 1;
fi

if [ -z "${SERVICES:-}" ]; then
  echo "SERVICES environment variable must be set"
  exit 1;
fi

# Enable access to service plans
# Services should be a set of "$name" or "$name:$plan" values, such as
# "redis28-multinode mongodb30-multinode:persistent"
for SERVICE in $SERVICES; do
  SERVICE_NAME=$(echo "${SERVICE}:" | cut -d ':' -f1)
  SERVICE_PLAN=$(echo "${SERVICE}:" | cut -d ':' -f2)
  ARGS=("${SERVICE_NAME}")
  if [ -n "${SERVICE_PLAN}" ]; then ARGS+=("-p" "${SERVICE_PLAN}"); fi
  if [ -n "${BROKER_NAME}" ]; then ARGS+=("-b" "${BROKER_NAME}"); fi

  # if we have a denylist, then we enable for all organizations EXCEPT those
  # since CF doesn't suport this; enumerate all organizations, and filter out those on the denylist
  # and enable for each remaining org
  if [ -n "${SERVICE_ORGANIZATION_DENYLIST:-}" ]; then

    for org in $(cf orgs | tail -n +4 | grep -Fvxf <(echo "$SERVICE_ORGANIZATION_DENYLIST" | tr " " "\n")); do
      cf enable-service-access "${ARGS[@]}" -o "${org}"
    done

  else
    # if we don't have a denylist, but do have an allowlist, then iterate over that list
    # and enable  for each of those orgs
    if [ -n "${SERVICE_ORGANIZATION:-}" ]; then

      for org in $(echo "${SERVICE_ORGANIZATION}" | tr " " "\n"); do
        cf enable-service-access "${ARGS[@]}" -o "${org}"
      done

    # if we don't have any kind of list, enable for all orgs
    else

      cf enable-service-access "${ARGS[@]}"

    fi
  fi
done
