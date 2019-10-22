#!/bin/bash

##
echo "START: setup..."
##

cd environments/setup/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id:?}" \
               -backend-config="key=${TF_VAR_tfstate_setup_key:?}"
terraform validate -var "codecommit_api_branch=${codecommit_api_branch:?}" \
                   -var "codecommit_web_branch=${codecommit_web_branch:?}"
terraform plan -var "codecommit_api_branch=${codecommit_api_branch}" \
               -var "codecommit_web_branch=${codecommit_web_branch}"
terraform apply -auto-approve \
                -var "codecommit_api_branch=${codecommit_api_branch}" \
                -var "codecommit_web_branch=${codecommit_web_branch}"

s3_bucket_audit_log_id=$(terraform output s3_bucket_audit_log_id)
echo "s3_bucket_audit_log_id: ${s3_bucket_audit_log_id}"

cd - || exit 99

##
echo "START: base..."
##

cd environments/service/base/pre/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_pre_key:?}"
resource_prefix="${TF_VAR_service_name:?}-${TF_VAR_stage:?}"
terraform validate -var "resource_prefix=${resource_prefix}" \
                   -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}"
terraform plan -var "resource_prefix=${resource_prefix}" \
               -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}"
terraform apply -auto-approve \
                -var "resource_prefix=${resource_prefix}" \
                -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}"

cloudformation_api_stack=$(terraform output cloudformation_api_stack)
echo "cloudformation_api_stack: ${cloudformation_api_stack}"

firehose_delivery_stream_arn=$(terraform output firehose_delivery_stream_arn)
echo "firehose_delivery_stream_arn: ${firehose_delivery_stream_arn}"

iam_role_api_log_cloudwatchlogs_to_s3_policy_arn=$( \
    terraform output iam_role_api_log_cloudwatchlogs_to_s3_policy_arn \
)
echo "iam_role_api_log_cloudwatchlogs_to_s3_policy_arn: ${iam_role_api_log_cloudwatchlogs_to_s3_policy_arn}"

codebuild_name=$(terraform output codebuild_tool_name)

cd - || exit 99

./bin/exec_codebuild.sh "${codebuild_name}" master

##
echo "START: api..."
##

cd environments/service/api/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_api_key:?}"
terraform validate
terraform plan
terraform apply -auto-approve

codebuild_name=$(terraform output codebuild_api_name)
echo "codebuild_name: ${codebuild_name}"

cd - || exit 99

./bin/exec_codebuild.sh "${codebuild_name}" "${codecommit_api_branch}"
TF_VAR_apigw_api_id=$( \
    aws cloudformation describe-stack-resource --stack-name "${cloudformation_api_stack}" \
                                               --logical-resource-id ApiGatewayRestApi | \
    jq -r '.StackResourceDetail.PhysicalResourceId' \
)
echo "TF_VAR_apigw_api_id: ${TF_VAR_apigw_api_id}"
export TF_VAR_apigw_api_id
./bin/mapping_logs_firehose.sh "${cloudformation_api_stack}" \
                               "${firehose_delivery_stream_arn}" \
                               "${iam_role_api_log_cloudwatchlogs_to_s3_policy_arn}"

##
echo "START: base..."
##

cd environments/service/base/after_api/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_after_api_key:?}"
terraform validate
terraform plan
terraform apply -auto-approve

cd - || exit 99

##
echo "START: web..."
##

cd environments/service/web/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_web_key:?}"
terraform validate
terraform plan
terraform apply -auto-approve

codebuild_name=$(terraform output codebuild_web_name)
echo "codebuild_name: ${codebuild_name}"

cd - || exit 99

./bin/exec_codebuild.sh "${codebuild_name}" "${codecommit_web_branch}"
