variable "stage" {}
variable "s3_bucket_terraform_state_id" {}
variable "tfstate_service_base_pre_key" {}
variable "apigw_api_id" {}

provider "aws" {}

terraform {
  required_version = ">= 0.11.0"

  backend "s3" {
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "service_base_pre" {
  backend = "s3"

  config {
    bucket = "${var.s3_bucket_terraform_state_id}"
    key    = "${var.tfstate_service_base_pre_key}"
    region = "ap-northeast-1"
  }
}

locals {
  resource_prefix = "${data.terraform_remote_state.service_base_pre.resource_prefix}"
}

module "cloudfront_api" {
  source                           = "../../../../modules/cloudfront/api"
  resource_prefix                  = "${local.resource_prefix}"
  stage                            = "${var.stage}"
  apigw_api_domain_name            = "${var.apigw_api_id}.execute-api.ap-northeast-1.amazonaws.com"
  s3_bucket_audit_log_domain_name  = "${data.terraform_remote_state.service_base_pre.s3_bucket_audit_log_domain_name}"
  waf_acl_id                       = "${data.terraform_remote_state.service_base_pre.waf_acl_id}"
}

output "api_base_url" {
  value = "https://${module.cloudfront_api.domain_name}"
}
