#!/bin/bash
set -eux

export AWS_DEFAULT_REGION=${DESTINATION_REGION}
aws s3 sync --source-region=${SOURCE_REGION} \
        --sse=AES256 \
        --metadata-directive=COPY \
        s3://${SOURCE_BUCKET}/${SUBDIRECTORY} \
        s3://${DESTINATION_BUCKET}/${SUBDIRECTORY}
