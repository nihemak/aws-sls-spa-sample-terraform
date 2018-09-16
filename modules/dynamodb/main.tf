variable "resource_prefix" {}

resource "aws_dynamodb_table" "todos" {
  name           = "${var.resource_prefix}-todos"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
