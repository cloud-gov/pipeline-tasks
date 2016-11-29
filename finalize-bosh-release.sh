#!/bin/bash
# vim: set ft=sh

set -e -u

cd release-git-repo
RELEASE_NAME=`ls releases`

tar -zxf ../final-builds-dir-tarball/final-builds-dir-${RELEASE_NAME}.tgz
tar -zxf ../releases-dir-tarball/releases-dir-${RELEASE_NAME}.tgz
cat <<EOF > "config/private.yml"
$PRIVATE_YML_CONTENT
EOF

if [ -n "$FINAL_YML_CONTENT" ]; then
cat <<EOF > "config/final.yml"
$FINAL_YML_CONTENT
EOF
fi

bosh-cli -n create-release --force --final --tarball

mv releases/${RELEASE_NAME}/*.tgz ../finalized-release
tar -czhf ../finalized-release/final-builds-dir-${RELEASE_NAME}.tgz .final_builds
tar -czhf ../finalized-release/releases-dir-${RELEASE_NAME}.tgz releases
