#!/bin/bash
# vim: set ft=sh

set -e

#
# A little environment validation
#
if [ -z "$PRIVATE_YML_CONTENT" ]; then
  echo "must specify \$PRIVATE_YML_CONTENT" >&2
  exit 1
fi

cd release-git-repo
RELEASE_NAME=`ls releases`

tar -zxf ../final-builds-dir-tarball/final-builds-dir-${RELEASE_NAME}.tgz
tar -zxf ../releases-dir-tarball/releases-dir-${RELEASE_NAME}.tgz
cat <<EOF > "config/private.yml"
$PRIVATE_YML_CONTENT
EOF

bosh -n create release --force --final --with-tarball

mv releases/${RELEASE_NAME}/*.tgz ../finalized-release
tar -czhf ../finalized-release/final-builds-dir-${RELEASE_NAME}.tgz .final_builds
tar -czhf ../finalized-release/releases-dir-${RELEASE_NAME}.tgz releases
