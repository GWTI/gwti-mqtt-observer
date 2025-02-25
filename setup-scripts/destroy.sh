#!/bin/bash

set -e

# Get the current working directory
CWD=$(pwd)

# Define functions
source "${CWD}/setup-scripts/functions.sh"

# Source global variables
source "${CWD}/setup-scripts/variables/global.sh"

# Check if BACKUP environment variable is set
if [ -n "${BACKUP}" ]; then
  echo "HAVE YOU BACKED UP THE DYNAMO DB?"
  read -r -p "Is this correct? (yes/no): " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Great! Make sure you have done this as this process will delete contents."
  else
    echo "Please back up your DynamoDB table. You cannot proceed without a backup."
    exit 1
  fi
fi

# Check if BUILD_STAGE environment variable is set
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

# Override STAGE with BUILD_STAGE
export STAGE="${BUILD_STAGE}"
export TF_VAR_STAGE="${STAGE}"

# Source stage-specific variables (if any)
if [ -f "${CWD}/setup-scripts/variables/${BUILD_STAGE}.sh" ]; then
  source "${CWD}/setup-scripts/variables/${BUILD_STAGE}.sh"
fi

# Destroy the Serverless application first (reverse order of deployment)
destroyServerless "${BUILD_STAGE}"

# Destroy Terraform resources
destroyTerraform "${BUILD_STAGE}"