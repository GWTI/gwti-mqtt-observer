#!/bin/bash

export CWD=$(pwd)
export REGION=eu-west-2
export AWS_DEFAULT_REGION="${REGION}"
export SERVICE=gwti-mqtt-observer
export STAGE="${BUILD_STAGE}"
export TF_VAR_STAGE="${STAGE}"
export TF_VAR_SERVICE="${SERVICE}"
export TF_VAR_REGION="${REGION}"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

export S3_TERRAFORM_STATE_BUCKET=gwti-mqtt-observer-terraform-state
export S3_TERRAFORM_STATE_KEY_PREFIX="${REGION}/${SERVICE}"
export S3_TERRAFORM_STATE_REGION=eu-west-2