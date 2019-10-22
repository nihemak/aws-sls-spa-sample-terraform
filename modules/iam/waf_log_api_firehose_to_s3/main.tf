variable "path" {}
variable "resource_prefix" {}
variable "s3_bucket_arn" {}

## role

data "template_file" "iam_assume_role_policy_waf_log_api_firehose_to_s3" {
  template = "${file("${var.path}/assume_role_policy.json")}"
}

resource "aws_iam_role" "waf_log_api_firehose_to_s3" {
  name               = "${var.resource_prefix}-waf-log-api-firehose-to-s3-role-01"
  assume_role_policy = "${data.template_file.iam_assume_role_policy_waf_log_api_firehose_to_s3.rendered}"
}

## role policy

data "template_file" "iam_policy_waf_log_api_firehose_to_s3" {
  template = "${file("${var.path}/policy.json")}"

  vars = {
    s3_bucket_arn = "${var.s3_bucket_arn}"
  }
}

resource "aws_iam_role_policy" "waf_log_api_firehose_to_s3" {
  name   = "${var.resource_prefix}-waf-log-api-firehose-to-s3-policy-01"
  role   = "${aws_iam_role.waf_log_api_firehose_to_s3.id}"
  policy = "${data.template_file.iam_policy_waf_log_api_firehose_to_s3.rendered}"
}

## outputs

output "arn" {
  value = "${aws_iam_role.waf_log_api_firehose_to_s3.arn}"
}
