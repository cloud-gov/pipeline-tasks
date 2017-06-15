#!/bin/bash
# vim: set ft=sh

set -e

#
# Validate environment
#
if [[ -n "${LINTER_CONFIG}" && ! -f "pipeline-config/${LINTER_CONFIG}" ]]; then
  echo "\$LINTER_CONFIG '${LINTER_CONFIG}' not found" >&2
  exit 1
fi
if [ -z "$MANIFEST_FILE" ]; then
  echo "You must specify \$MANIFEST_FILE" >&2
  exit 1
fi
if [ -z $(which bosh-lint) ]; then
  echo "bosh-lint not found" >&2
  exit 1
fi

#
# lint the manifest, using a $LINTER_CONFIG if provided
#
if [ -n "${LINTER_CONFIG}" ]; then
  bosh-lint lint-manifest --config "pipeline-config/${LINTER_CONFIG}" "lint-manifest/${MANIFEST_FILE}"
else
  bosh-lint lint-manifest "lint-manifest/${MANIFEST_FILE}"
fi
