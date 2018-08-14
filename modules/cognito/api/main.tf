variable "resource_prefix" {}

resource "aws_cognito_user_pool" "api" {
  name                     = "${var.resource_prefix}-api-01"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
  }

  admin_create_user_config {
    invite_message_template {
      email_subject = "仮パスワード"
      email_message = " ユーザー名は {username} 仮パスワードは {####} です。"
      sms_message = " ユーザー名は {username} 仮パスワードは {####} です。"
    }
  }

  verification_message_template {
    email_subject = "確認コード通知"
    email_message = " 検証コードは {####} です。"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.resource_prefix}-web-01"
  user_pool_id = "${aws_cognito_user_pool.api.id}"

  read_attributes = [
    "given_name",
    "email_verified",
    "zoneinfo",
    "website",
    "preferred_username",
    "name",
    "locale",
    "phone_number",
    "family_name",
    "birthdate",
    "middle_name",
    "phone_number_verified",
    "profile",
    "picture",
    "address",
    "gender",
    "updated_at",
    "nickname",
    "email"
  ]

  write_attributes = [
    "given_name",
    "zoneinfo",
    "website",
    "preferred_username",
    "name",
    "locale",
    "phone_number",
    "family_name",
    "birthdate",
    "middle_name",
    "profile",
    "picture",
    "address",
    "gender",
    "updated_at",
    "nickname",
    "email"
  ]
}

output "id" {
  value = "${aws_cognito_user_pool.api.id}"
}

output "arn" {
  value = "${aws_cognito_user_pool.api.arn}"
}

output "client_web_id" {
  value = "${aws_cognito_user_pool_client.web.id}"
}
