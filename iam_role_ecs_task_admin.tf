# Execute Commandを実行するための権限を設定する。
resource "aws_iam_role" "ecs_task_admin" {
  name = "${local.prefix}-ecs-task-admin"
  # NOTE: assume_role_policy はecs_taskと同じものを使い回す。
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_admin" {

  # NOTE: aws execute-commandでコンテナへ接続するための権限
  # see: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html#ecs-exec-enabling-and-using
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  # NOTE: ログをCloudWatch Logsに保存する権限
  # see: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html#ecs-exec-logging
  statement {
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.ecs["admin"].arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_admin" {
  name        = "${local.prefix}-ecs-task-admin"
  description = "${local.prefix}-ecs-task-admin"
  policy      = data.aws_iam_policy_document.ecs_task_admin.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_admin" {
  role       = aws_iam_role.ecs_task_admin.name
  policy_arn = aws_iam_policy.ecs_task_admin.arn
}
