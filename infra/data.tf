data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "privates" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution" {

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Secrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.secrets.arn]
  }
}

data "aws_iam_policy_document" "task_permission" {
  statement {
    sid    = "S3StaticFilePermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject*",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.static.arn,
      "${aws_s3_bucket.static.arn}/*",
    ]
  }
}

#####
## Code deploy
#####
data "aws_iam_policy_document" "code_deploy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "code_deploy_pass_role" {
  statement {
    sid       = "AllowCodeDeployToPassRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole", "iam:GetRole"]
    resources = [aws_iam_role.execution_role.arn, aws_iam_role.task_role.arn]
  }
}