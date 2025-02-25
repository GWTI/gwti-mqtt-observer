#!/bin/bash

set -e

CWD=$(pwd)
source "${CWD}/setup-scripts/functions.sh"
source "${CWD}/setup-scripts/variables/global.sh"

if [ -n "${BACKUP}" ]; then
  echo "HAVE YOU BACKED UP THE DYNAMO DB?"
  read -r -p "Is this correct? (yes/no): " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Great! Make sure you have done this as this process can delete contents."
  else
    echo "Please back up your DynamoDB table. You cannot proceed without a backup."
    exit 1
  fi
fi

if [ -n "${BUILD_STAGE}" ]; then
  echo "BUILD_STAGE is set to '$BUILD_STAGE'."
  read -r -p "Is this correct? (yes/no): " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Great! BUILD_STAGE is confirmed as '$BUILD_STAGE'."
  else
    read -r -p "Please enter the correct value for BUILD_STAGE: " BUILD_STAGE
    echo "BUILD_STAGE is now set to '$BUILD_STAGE'."
  fi
else
  read -r -p "BUILD_STAGE is not set. Please enter the value for BUILD_STAGE: " BUILD_STAGE
  echo "BUILD_STAGE is now set to '$BUILD_STAGE'."
fi

export STAGE="${BUILD_STAGE}"
export TF_VAR_STAGE="${STAGE}"

if [ -f "${CWD}/setup-scripts/variables/${BUILD_STAGE}.sh" ]; then
  source "${CWD}/setup-scripts/variables/${BUILD_STAGE}.sh"
fi

createTerraformBucket
createServerlessBucket
deployTerraform "${BUILD_STAGE}"
deployServerless "${BUILD_STAGE}"