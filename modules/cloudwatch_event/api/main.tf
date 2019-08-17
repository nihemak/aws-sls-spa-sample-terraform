variable "path" {}
variable "resource_prefix" {}
variable "aws_account_id" {}
variable "codecommit_repository" {}

data "template_file" "event_pattern_api" {
  template = "${file("${var.path}/event_pattern.json")}"

  vars = {
    codecommit_arn = "arn:aws:codecommit:ap-northeast-1:${var.aws_account_id}:${var.codecommit_repository}"
  }
}

resource "aws_cloudwatch_event_rule" "api" {
  name = "${var.resource_prefix}-codepipeline-api-rule-01"

  event_pattern = "${data.template_file.event_pattern_api.rendered}"
}

output "name" {
  value = "${aws_cloudwatch_event_rule.api.name}"
}
