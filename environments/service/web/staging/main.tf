variable "stage" {}
variable "s3_bucket_terraform_state_id" {}
variable "tfstate_setup_key" {}
variable "tfstate_service_base_pre_key" {}
variable "tfstate_service_base_after_api_key" {}

provider "aws" {
  version = ">= 2.24"
}

provider "template" {
  version = ">= 2.1"
}

terraform {
  required_version = ">= 0.12.6"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "setup" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_setup_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_base_pre" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_base_pre_key}"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_base_after_api" {
  backend = "s3"

  config = {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_base_after_api_key}"
    region = "ap-northeast-1"
  }
}

locals {
  resource_prefix = "${data.terraform_remote_state.service_base_pre.outputs.resource_prefix}"
}

module "iam_role_build_web" {
  source                  = "../../../../modules/iam/build_web/staging"
  path                    = "../../../../modules/iam/build_web/staging"
  aws_account_id          = "${data.aws_caller_identity.current.account_id}"
  resource_prefix         = "${local.resource_prefix}"
  s3_bucket_web_arn       = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_web_arn}"
  s3_bucket_source_arn    = "${data.terraform_remote_state.setup.outputs.s3_bucket_artifacts_arn}"
}

module "s3_bucket_policy_web" {
  source                            = "../../../../modules/s3/bucket_policy/web"
  path                              = "../../../../modules/s3/bucket_policy/web"
  cloudfront_origin_access_identity = "${data.terraform_remote_state.service_base_pre.outputs.cloudfront_web_origin_access_identity}"
  s3_bucket_web_id                  = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_web_id}"
  s3_bucket_web_arn                 = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_web_arn}"
  iam_role_build_web_arn            = "${module.iam_role_build_web.arn}"
}

module "codebuild_web" {
  source                  = "../../../../modules/codebuild/web/staging"
  codecommit_repository   = "${data.terraform_remote_state.setup.outputs.codecommit_web_repository}"
  s3_bucket_source_id     = "${data.terraform_remote_state.setup.outputs.s3_bucket_artifacts_id}"
  resource_prefix         = "${local.resource_prefix}"
  stage                   = "${var.stage}"
  s3_bucket_web_id        = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_web_id}"
  iam_role_build_web_arn  = "${module.iam_role_build_web.arn}"
  cognito_pool_id         = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_id}"
  cognito_pool_client_id  = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_client_web_id}"
  api_base_url            = "${data.terraform_remote_state.service_base_after_api.outputs.api_base_url}"
}

module "iam_role_e2e" {
  source          = "../../../../modules/iam/e2e"
  path            = "../../../../modules/iam/e2e"
  resource_prefix = "${local.resource_prefix}"
}

module "codebuild_e2e" {
  source                 = "../../../../modules/codebuild/e2e"
  resource_prefix        = "${local.resource_prefix}"
  codecommit_repository  = "${data.terraform_remote_state.setup.outputs.codecommit_web_repository}"
  iam_role_e2e_arn       = "${module.iam_role_e2e.arn}"
  cognito_pool_id        = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_id}"
  cognito_pool_client_id = "${data.terraform_remote_state.service_base_pre.outputs.cognito_pool_api_client_web_id}"
  api_base_url           = "${data.terraform_remote_state.service_base_after_api.outputs.api_base_url}"
}

output "codebuild_web_name" {
  value = "${module.codebuild_web.name}"
}

output "codebuild_e2e_name" {
  value = "${module.codebuild_e2e.name}"
}
