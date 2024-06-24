resource "aws_iam_role" "execution_role" {
  name               = "${var.prefix}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "task_role" {
  name               = "${var.prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "execution_policy" {
  name   = "${var.prefix}-execution-policy"
  policy = data.aws_iam_policy_document.execution.json
  role   = aws_iam_role.execution_role.id
}

resource "aws_iam_role_policy" "task_policy" {
  name   = "${var.prefix}-task-policy"
  policy = data.aws_iam_policy_document.task_permission.json
  role   = aws_iam_role.task_role.id
}
