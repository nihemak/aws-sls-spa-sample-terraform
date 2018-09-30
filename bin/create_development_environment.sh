#!/bin/bash

## setup

cd environments/setup/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id:?}" \
               -backend-config="key=${TF_VAR_tfstate_setup_key:?}"
terraform plan -var "codecommit_api_branch=${codecommit_api_branch:?}" \
               -var "codecommit_web_branch=${codecommit_web_branch:?}"
terraform apply -auto-approve \
                -var "codecommit_api_branch=${codecommit_api_branch}" \
                -var "codecommit_web_branch=${codecommit_web_branch}"
s3_bucket_audit_log_id=$(terraform output s3_bucket_audit_log_id)
s3_bucket_audit_log_bucket_domain_name=$(terraform output s3_bucket_audit_log_bucket_domain_name)
s3_bucket_api_log_arn=$(terraform output s3_bucket_api_log_arn)

cd - || exit 99

## base

cd environments/service/base/pre/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_pre_key:?}"
resource_prefix="${TF_VAR_service_name:?}-${TF_VAR_stage:?}"
terraform plan -var "resource_prefix=${resource_prefix}" \
               -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}" \
               -var "s3_bucket_audit_log_bucket_domain_name=${s3_bucket_audit_log_bucket_domain_name}" \
               -var "s3_bucket_api_log_arn=${s3_bucket_api_log_arn}"
terraform apply -auto-approve \
                -var "resource_prefix=${resource_prefix}" \
                -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}" \
                -var "s3_bucket_audit_log_bucket_domain_name=${s3_bucket_audit_log_bucket_domain_name}" \
                -var "s3_bucket_api_log_arn=${s3_bucket_api_log_arn}"
cloudformation_api_stack=$(terraform output cloudformation_api_stack)
firehose_delivery_stream_arn=$(terraform output firehose_delivery_stream_arn)
iam_role_api_log_cloudwatchlogs_to_s3_policy_arn=$( \
    terraform output iam_role_api_log_cloudwatchlogs_to_s3_policy_arn \
)

cd - || exit 99

## api

cd environments/service/api/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_api_key:?}"
terraform plan
terraform apply -auto-approve
codebuild_name=$(terraform output codebuild_api_name)

cd - || exit 99

./bin/exec_codebuild.sh "${codebuild_name}" "${codecommit_api_branch}"
TF_VAR_apigw_api_id=$( \
    aws cloudformation describe-stack-resource --stack-name "${cloudformation_api_stack}" \
                                               --logical-resource-id ApiGatewayRestApi | \
    jq -r '.StackResourceDetail.PhysicalResourceId' \
)
export TF_VAR_apigw_api_id
./bin/mapping_logs_firehose.sh "${cloudformation_api_stack}" \
                               "${firehose_delivery_stream_arn}" \
                               "${iam_role_api_log_cloudwatchlogs_to_s3_policy_arn}"

## base

cd environments/service/base/after_api/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_after_api_key:?}"
terraform plan
terraform apply -auto-approve

cd - || exit 99

## web

cd environments/service/web/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_web_key:?}"
terraform plan
terraform apply -auto-approve
codebuild_name=$(terraform output codebuild_web_name)

cd - || exit 99

./bin/exec_codebuild.sh "${codebuild_name}" "${codecommit_web_branch}"
