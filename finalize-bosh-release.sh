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
LAST_VERSION=$(ls releases/${RELEASE_NAME}/${RELEASE_NAME}*.yml | grep -oe '[0-9]\+.yml'| cut -d'.' -f1 | sort -n |tail -1)
NEW_VERSION=$(($LAST_VERSION+1))

bosh-cli -n create-release --force --final --tarball=finalized-release/${RELEASE_NAME}-${NEW_VERSION}.tgz

tar -czhf ../finalized-release/final-builds-dir-${RELEASE_NAME}.tgz .final_builds
tar -czhf ../finalized-release/releases-dir-${RELEASE_NAME}.tgz releases
