#!/bin/bash
set -e
set -u

USAGE="Usage: secrets.sh ARGUMENTS
This script needs to be run in a cg-deploy-* repo

Operations (only use 1):
\t-d, --decrypt\tDecrypt secrets for your current
\t-e, --encrypt\tDecrypt secrets for your current
\t-c, --check\tDo a healthcheck to make sure the repo is setup correctly
\t-h, --help\tThis help will print

Options:
\t-g, --govcloud\tAdd govcloud suffix to all files

Required Environment Variables:
\tAWS_ACCESS_KEY_ID - Amazon AWS Access Key
\tAWS_SECRET_ACCESS_KEY - Amazon Secret Access Key
\tAWS_DEFAULT_REGION - Default Amazon Region

Optional Environment Variables:
\tCONCOURSE_BUCKET - Bucket with Concourse credentials

Examples:

Decrypt GovCloud secrets:
\t./secrets.sh -d -g

Encrypt GovCloud secrets:
\t./secrets.sh -e -g
"

if [[ $# -lt 1 ]]; then
  echo -e "${USAGE}"
  exit 1
fi

DECRYPT=0
ENCRYPT=0
CHECK=0
GOVCLOUD=0

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
    -d|--decrypt)
      DECRYPT=1
      ;;
    -e|--encrypt)
      ENCRYPT=1
      ;;
    -c|--check)
      CHECK=1
      ;;
    -g|--govcloud)
      GOVCLOUD=1
      ;;
    *)
      echo "${key} is not even close to a valid option."
      echo -e "${USAGE}"
      exit 1
      ;;
  esac
  shift
done

# Encrypt / Decrypt / Healthcheck only, otherwise exit
if [ $((${DECRYPT} + ${ENCRYPT} + ${CHECK})) -ne 1 ]; then
  echo  -e "${USAGE}"
  exit 1
fi

DIR=`basename "$PWD"`
PIPELINE_TASKS="$HOME/.cloudgov/cg-pipeline-tasks"

# Check that we are in a compatible directory
echo "${DIR}" | egrep '^cg-deploy-[a-zA-Z0-9-]+$' || { echo "${0} is only compatible with cg-deploy-* repos"; exit 1; }

# Check exists? AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY, AWS_ACCESS_KEY_ID
# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${AWS_DEFAULT_REGION+x} ]; then
  echo "AWS_DEFAULT_REGION must be set"
  exit 1
fi

if [ -z ${AWS_SECRET_ACCESS_KEY+x} ]; then
  echo "AWS_SECRET_ACCESS_KEY must be set"
  exit 1
fi

if [ -z ${AWS_ACCESS_KEY_ID+x} ]; then
  echo "AWS_ACCESS_KEY_ID must be set"
  exit 1
fi

command -v aws >/dev/null 2>&1 || { echo "AWS CLI required: http://docs.aws.amazon.com/cli/latest/userguide/installing.html"; exit 1; }

if [ ! -d "${PIPELINE_TASKS}/.git" ]; then
  echo "cg-pipeline-tasks is required to encrypted and decrypt secrets"
  read -p "We cannot find a git repo, clone it now [Y/N]?" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "${PIPELINE_TASKS} cannot be found, aborting."
    exit 1
  else
    mkdir -p ${PIPELINE_TASKS}
    git clone https://github.com/18F/cg-pipeline-tasks ${PIPELINE_TASKS}
  fi
fi

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

if [ "${CURRENT_BRANCH}" = "master" ]; then
  TARGET_ENVIRONMENT="production"
elif [ "${CURRENT_BRANCH}" = "staging" ]; then
  TARGET_ENVIRONMENT="staging"
else
  echo "Secrets currently only exist for production / staging, please"
  echo "checkout one of those branches and try again."
  exit 1
fi

# The reason we won't display call it monitoring.yml or cf.yml is these
# often conflict with files in the actual repo, ie bosh manifests
BASEFILE=`echo "${DIR}" | sed 's/^cg-deploy-\([a-zA-Z0-9-]\+\)$/\1/'`
ENCRYPTED_FILENAME=`echo "${BASEFILE}-${TARGET_ENVIRONMENT}-encrypted-secrets.yml"`
FILENAME=`echo "${BASEFILE}-${TARGET_ENVIRONMENT}-secrets.yml"`

if [ ${GOVCLOUD} -eq 1 ]; then
  FILENAME=`echo "${BASEFILE}-${TARGET_ENVIRONMENT}-govcloud-secrets.yml"`
fi

if [ ! -f ".gitignore" ]; then
  echo "You should have a .gitignore file with common sense defaults"
  echo "https://github.com/18F/cg-deploy-cf/blob/staging/.gitignore"
fi

egrep -q "^${ENCRYPTED_FILENAME}$" .gitignore || { echo ".gitignore does not have ${ENCRYPTED_FILENAME} listed"; exit 1; }
egrep -q "^${FILENAME}$" .gitignore || { echo ".gitignore does not have ${FILENAME} listed"; exit 1; }

if [ ! -d ./ci ]; then
  echo "Each project should have a ci directory, creating"
  mkdir ci
fi

if [ ! -f "ci/credentials.yml" ]; then
  echo "Populated credentials are needed to use secrets"
  read -p "Download credentials form S3 [Y/N]?" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "ci/credentials.yml cannot be found, aborting."
    exit 1
  else
    if [ -z ${CONCOURSE_BUCKET+x} ]; then
      echo "CONCOURSE_BUCKET was not passed, so we cannot automatically 
download credentials.  Execute with: CONCOURSE_BUCKET=bucket ${0}"
      exit 1
    else
      aws s3 cp s3://${CONCOURSE_BUCKET}/${DIR}.yml ci/${DIR}.yml
    fi
  fi
fi

if [ ! -f ./ci/pipeline.yml ]; then
  echo "Could not locate the pipeline.yml, this repo is not setup correctly"
  echo "A populated pipeline can be downloaded via fly, but this is"
  echo "not the recommended way to do it."
  exit 1
fi

CHECK_TARGET_ENVIRONMENT=`grep "${TARGET_ENVIRONMENT}" ci/pipeline.yml` || \
  { echo "Could not find ${TARGET_ENVIRONMENT} in ci/pipeline.yml"; exit 1; }

BUCKET=`grep "${TARGET_ENVIRONMENT}" ci/credentials.yml |
  egrep "^${BASEFILE}-private-bucket-${TARGET_ENVIRONMENT}:\s+[a-zA-Z0-9-]+\$" |
  sed "s/^${BASEFILE}-private-bucket-${TARGET_ENVIRONMENT}:\s\+\([a-zA-Z0-9-]\+\)\$/\1/"` ||
  { echo "Could not get bucket from ${BASEFILE}-private-bucket-${TARGET_ENVIRONMENT} \
    in ci/credentials.yml"; exit 1; }

PASSPHRASE_VARIABLE=`grep "${TARGET_ENVIRONMENT}" ci/pipeline.yml | \
  egrep '^\s*secrets_passphrase: {{[a-zA-Z0-9-]+}}$' | \
  sed 's/\s\+secrets_passphrase: {{\([a-zA-Z0-9-]\+\)}}.*/\1/'` || \
  { echo "Could not find a secrets_passphrase variable in the pipeline"; exit 1; }

PASSPHRASE=`egrep "^${PASSPHRASE_VARIABLE}:\s+" ci/credentials.yml | \
  sed "s/^${PASSPHRASE_VARIABLE}:\s\+\(.*\)$/\1/"` || \
  { echo "Could not find ${PASSPHRASE_VARIABLE} variable in the credentials"; exit 1; }

if [ ${CHECK} -eq 1 ]; then
  echo "Check complete, looks good!"
  exit 0
fi

export PASSPHRASE="${PASSPHRASE}"
if [ ${ENCRYPT} -eq 1 ]; then
  export INPUT_FILE=${FILENAME}
  export OUTPUT_FILE=${ENCRYPTED_FILENAME}

  vi ${INPUT_FILE}
  read -p "Encrypt and upload via S3 [Y/N]?" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "User aborted prior to encrypt / upload."
    exit 1
  fi

  ${PIPELINE_TASKS}/encrypt.sh
  aws s3 cp ${ENCRYPTED_FILENAME} s3://${BUCKET}/${ENCRYPTED_FILENAME} 
elif [ ${DECRYPT} -eq 1 ]; then
  aws s3 cp s3://${BUCKET}/${ENCRYPTED_FILENAME} ${ENCRYPTED_FILENAME}
  export INPUT_FILE=${ENCRYPTED_FILENAME}
  export OUTPUT_FILE=${FILENAME}
  ${PIPELINE_TASKS}/decrypt.sh
  vi ${OUTPUT_FILE}
fi

exit 0
