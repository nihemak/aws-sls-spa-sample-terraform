variable "s3_bucket_terraform_state_id" {}
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

module "glue" {
  source                           = "../../../../modules/glue"
  resource_prefix                  = "${local.resource_prefix}"
  s3_bucket_id_cloudfront_api_logs = "${data.terraform_remote_state.service_base_after_api.outputs.s3_bucket_id_cloudfront_api_logs}"
  s3_bucket_id_cloudfront_web_logs = "${data.terraform_remote_state.service_base_pre.outputs.s3_bucket_id_cloudfront_web_logs}"
}
