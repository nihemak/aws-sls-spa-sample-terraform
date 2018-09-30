#!/bin/bash

# Workaround until TF supports creds via Task Roles when running on ECS or CodeBuild
# See: https://github.com/hashicorp/terraform/issues/8746
AWS_RAW_CRED=$(curl --silent "http://169.254.170.2:80${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI}")
AWS_ACCESS_KEY_ID=$(echo "${AWS_RAW_CRED}" | jq -r '.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "${AWS_RAW_CRED}" | jq -r '.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "${AWS_RAW_CRED}" | jq -r '.Token')

export AWS_RAW_CRED
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
