resource "aws_iam_user" "user" {
  name = "${var.instance_name}-s3-service-user"
  path = "/system/"
}

resource "aws_iam_access_key" "access_key" {
  user       = aws_iam_user.user.name
  depends_on = [aws_iam_user.user]
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
data "aws_s3_bucket" "target_bucket" {
  bucket = var.s3_bucket
}

data "aws_iam_policy_document" "s3_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "${data.aws_s3_bucket.target_bucket.arn}",
      "${data.aws_s3_bucket.target_bucket.arn}/*"
    ]
  }
  depends_on = [data.aws_s3_bucket.target_bucket]
}


resource "aws_iam_policy" "s3_service_user_policy" {
  name        = "${var.instance_name}-s3-service-user-policy"
  description = "${var.instance_name} should have access to only their bucket of client data."
  policy      = data.aws_iam_policy_document.s3_role_policy_document.json
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
  depends_on = [aws_iam_user.user]
}

# Create the role
resource "aws_iam_role" "role" {
  name               = "${var.instance_name}-s3-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  depends_on         = [data.aws_iam_policy_document.assume_role_policy_document]
}


# Attach the actual policy permissions to the role
resource "aws_iam_role_policy_attachment" "role_s3_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.s3_service_user_policy.arn
}