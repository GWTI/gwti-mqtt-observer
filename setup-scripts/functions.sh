#!/bin/bash

function createTerraformBucket {
    echo "S3_TERRAFORM_STATE_BUCKET: ${S3_TERRAFORM_STATE_BUCKET}"
    if ! aws s3api head-bucket --bucket "${S3_TERRAFORM_STATE_BUCKET}" 2>/dev/null; then
        aws s3api create-bucket \
            --bucket "${S3_TERRAFORM_STATE_BUCKET}" \
            --region "${S3_TERRAFORM_STATE_REGION}" \
            --create-bucket-configuration LocationConstraint="${S3_TERRAFORM_STATE_REGION}"
        echo "Created S3 bucket: ${S3_TERRAFORM_STATE_BUCKET}"
    else
        echo "S3 bucket ${S3_TERRAFORM_STATE_BUCKET} already exists."
    fi
}

function createServerlessBucket {
    # Shortened bucket name (max 63 chars)
    SERVERLESS_BUCKET="mqtt-obs-sls-${REGION}-${STAGE}-${AWS_ACCOUNT_ID}"
    echo "SERVERLESS_BUCKET: ${SERVERLESS_BUCKET}"
    if ! aws s3api head-bucket --bucket "${SERVERLESS_BUCKET}" 2>/dev/null; then
        aws s3api create-bucket \
            --bucket "${SERVERLESS_BUCKET}" \
            --region "${REGION}" \
            --create-bucket-configuration LocationConstraint="${REGION}"
        echo "Created Serverless deployment bucket: ${SERVERLESS_BUCKET}"
    else
        echo "Serverless deployment bucket ${SERVERLESS_BUCKET} already exists."
    fi
}

function terraformInit {
    echo "Initializing Terraform..."
    cd "${CWD}/terraform"
    terraform init \
        -backend-config="bucket=${S3_TERRAFORM_STATE_BUCKET}" \
        -backend-config="key=${S3_TERRAFORM_STATE_KEY_PREFIX}/${STAGE}/terraform.tfstate" \
        -backend-config="region=${S3_TERRAFORM_STATE_REGION}" \
        -reconfigure
}

function deployTerraform {
    echo "Deploying Terraform resources for stage: ${1}"
    rm -f "${CWD}/terraform/.terraform/terraform.tfstate"
    cd "${CWD}/terraform"
    terraformInit
    if [[ "$1" == "plan" ]]; then
        terraform plan -var "SERVICE=${SERVICE}" -var "STAGE=${STAGE}" -var "REGION=${REGION}"
    else
        terraform apply -var "SERVICE=${SERVICE}" -var "STAGE=${STAGE}" -var "REGION=${REGION}" -auto-approve -no-color
        terraform output -json | jq 'with_entries(.value |= .value)' > "${CWD}/terraform/terraform-state-${STAGE}.json"
    fi
}

function deployServerless {
    echo "Deploying Serverless application for stage: ${1}"
    cd "${CWD}"
    rm -rf .serverless
    TF_STATE=$(cat "${CWD}/terraform/terraform-state-${STAGE}.json")
    echo "Terraform state: ${TF_STATE}"
    if [[ "$1" == "plan" ]]; then
        serverless package --stage "${STAGE}" --region "${REGION}"
    else
        serverless deploy --verbose --stage "${STAGE}" --region "${REGION}" --force
    fi
}

function destroyTerraform {
    echo "Destroying Terraform resources for stage: ${STAGE}"
    cd "${CWD}/terraform"
    terraformInit
    terraform destroy -var "SERVICE=${SERVICE}" -var "STAGE=${STAGE}" -var "REGION=${REGION}" -auto-approve -no-color
}

function destroyServerless {
    echo "Destroying Serverless application for stage: ${STAGE}"
    cd "${CWD}"
    serverless remove --stage "${STAGE}" --region "${REGION}"
}