#!/bin/bash

##
echo "START: setup..."
##

cd environments/setup/staging_production/ || exit 99

terraform init -backend-config="bucket=${TF_VAR_s3_bucket_terraform_state_id:?}" \
               -backend-config="key=${TF_VAR_tfstate_setup_key:?}"
terraform validate
terraform plan
terraform apply -auto-approve

aws codepipeline start-pipeline-execution --name "$(terraform output codepipeline_service_name)"

cd - || exit 99
