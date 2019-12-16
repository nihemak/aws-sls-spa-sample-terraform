#!/bin/bash

##
echo "START: info..."
##

cd environments/service/web/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id:?}" \
               -backend-config="key=${TF_VAR_tfstate_service_web_key:?}"

codebuild_destroy_web_name=$(terraform output codebuild_destroy_web_name)
echo "codebuild_destroy_web_name: ${codebuild_destroy_web_name}"

cd - || exit 99

cd environments/service/api/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_api_key:?}"

codebuild_destroy_api_name=$(terraform output codebuild_destroy_api_name)
echo "codebuild_destroy_api_name: ${codebuild_destroy_api_name}"

cd - || exit 99

cd environments/service/base/pre/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_pre_key:?}"

cloudformation_api_stack=$(terraform output cloudformation_api_stack)
echo "cloudformation_api_stack: ${cloudformation_api_stack}"

TF_VAR_apigw_api_id=$( \
    aws cloudformation describe-stack-resource --stack-name "${cloudformation_api_stack}" \
                                               --logical-resource-id ApiGatewayRestApi | \
    jq -r '.StackResourceDetail.PhysicalResourceId' \
)
echo "TF_VAR_apigw_api_id: ${TF_VAR_apigw_api_id}"
export TF_VAR_apigw_api_id

cd - || exit 99

cd environments/setup/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_setup_key:?}"

s3_bucket_audit_log_id=$(terraform output s3_bucket_audit_log_id)
echo "s3_bucket_audit_log_id: ${s3_bucket_audit_log_id}"

cd - || exit 99

##
echo "START: base..."
##

cd environments/service/base/post/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_post_key:?}"
terraform validate
terraform plan
terraform destroy -auto-approve

cd - || exit 99

##
echo "START: web..."
##

./bin/exec_codebuild.sh "${codebuild_destroy_web_name}" "${codecommit_web_branch:?}"

cd environments/service/web/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_web_key}"
terraform plan -destroy
terraform destroy -auto-approve

cd - || exit 99

##
echo "START: base..."
##

cd environments/service/base/after_api/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_after_api_key:?}"
terraform plan -destroy
terraform destroy -auto-approve

cd - || exit 99

##
echo "START: api..."
##

./bin/mapping_logs_delete_firehose.sh "${cloudformation_api_stack}"
./bin/exec_codebuild.sh "${codebuild_destroy_api_name" "$codecommit_api_branch}"

cd environments/service/api/development/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_api_key}"
terraform plan -destroy
terraform destroy -auto-approve

cd - || exit 99

##
echo "START: base..."
##

cd environments/service/base/pre/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id}" \
               -backend-config="key=${TF_VAR_tfstate_service_base_pre_key}"
resource_prefix="${service_name:?}-${TF_VAR_stage:?}"
terraform plan -destroy \
               -var "resource_prefix=${resource_prefix}" \
               -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}"
terraform destroy -auto-approve \
                  -var "resource_prefix=${resource_prefix}" \
                  -var "s3_bucket_audit_log_id=${s3_bucket_audit_log_id}"

cd - || exit 99
