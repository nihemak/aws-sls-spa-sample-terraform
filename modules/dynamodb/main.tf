variable "resource_prefix" {}

resource "aws_dynamodb_table" "hoges" {
  name           = "${var.resource_prefix}-hoges"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name               = "userIdIndex"
    hash_key           = "userId"
    range_key          = "createdAt"
    write_capacity     = 1
    read_capacity      = 1
    projection_type    = "ALL"
  }
}

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
