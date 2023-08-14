# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
data "aws_s3_bucket" "target_bucket" {
  bucket = aws_s3_bucket.main_bucket.bucket
}

data "aws_dynamodb_table" "tableName" {
  name = aws_dynamodb_table.terraform_state_lock.name
}

locals {
  terraform_state_file_key                 = "${var.project}/${var.environment}/terraform.tfstate"
  terraform_state_credentials_path         = ".aws/${var.project}/${var.environment}/terraform_state"
  output_terraform_credential_profile_name = "${var.aws_profile}-terraform"
}


data "aws_iam_policy_document" "terraform_state_role_policy_document" {
  # Permissions policy for AWS Role to manage terraform state files and dynamoDB state locks.

  # https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-bucket-permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${data.aws_s3_bucket.target_bucket.arn}",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${data.aws_s3_bucket.target_bucket.arn}/${local.terraform_state_file_key}"
    ]
  }

  # https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-table-permissions
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${data.aws_dynamodb_table.tableName.name}"]
  }

  depends_on = [
    data.aws_s3_bucket.target_bucket,
    data.aws_dynamodb_table.tableName
  ]
}


resource "aws_iam_user" "user" {
  name = "terraform-state-${var.project}-service-user"
  path = "/system/"
}

resource "aws_iam_access_key" "access_key" {
  user       = aws_iam_user.user.name
  depends_on = [aws_iam_user.user]
}


resource "aws_iam_policy" "terraform_state_role_policy" {
  name        = "terraform-state-${var.project}-policy"
  description = "Manage terraform state files in S3 and DynamoDB state locks for ${var.project}."
  policy      = data.aws_iam_policy_document.terraform_state_role_policy_document.json
  depends_on  = [data.aws_iam_policy_document.terraform_state_role_policy_document]
}


# Establish trust relationship of WHO can assume this role
data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.user.arn]
    }
  }

}

# Create the role
resource "aws_iam_role" "role" {
  name               = "terraform-state-${var.project}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  depends_on         = [data.aws_iam_policy_document.assume_role_policy_document]
}


# Attach the actual policy permissions to the role
resource "aws_iam_role_policy_attachment" "role_s3_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.terraform_state_role_policy.arn
}

resource "local_sensitive_file" "terraform_user_credentials" {
  content  = <<-EOT
  [${local.output_terraform_credential_profile_name}]
  aws_access_key_id = ${aws_iam_access_key.access_key.id}
  aws_secret_access_key = ${aws_iam_access_key.access_key.secret}
  EOT
  filename = "${local.terraform_state_credentials_path}/credentials"
}

resource "local_file" "terraform_user_config" {
  content  = <<-EOT
  [${var.aws_profile}-terraform]
  region = ${var.aws_region}
  output = json
  EOT
  filename = "${local.terraform_state_credentials_path}/config"
}