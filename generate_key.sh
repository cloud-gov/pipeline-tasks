#!/bin/bash
# vim: set ft=sh

set -e

#
# A little environment validation
#
if [ -z "$PASSPHRASE" ]; then
  echo "must specify \$PASSPHRASE" >&2
  exit 1
fi

if [ -z "$BUCKET" ]; then
  echo "must specify \$BUCKET" >&2
  exit 1
fi

#
# Generate the key
#
TIME="$(date +"%s")"
NAME="bosh-$TIME"

openssl genrsa -out $NAME.pem 4096

openssl rsa -in $NAME.pem -pubout > $NAME.pub

#
# Upload to EC2 as an access key
#
aws ec2 import-key-pair --key-name $NAME --public-key-material `sed '1d;$d' $NAME.pub | tr -d '\n'`

#
# Encrypt it and upload it to S3
#
INPUT_FILE=$NAME.pem OUTPUT_FILE=$NAME.enc.pem ./encrypt.sh

aws s3 cp $NAME.enc.pem s3://$BUCKET/$NAME.enc.pem
