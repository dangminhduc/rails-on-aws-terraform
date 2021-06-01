data "aws_iam_policy_document" "ecs_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ecs" {
  name               = "${local.prefix}-ecs-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_iam_policy.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.ecs.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs.name
  policy_arn = aws_iam_policy.ecs.arn
}

resource "aws_iam_policy" "ecs" {
  name        = "${local.prefix}-ecs-iam-policy"
  description = "${local.prefix}-ecs-iam-policy"
  policy      = data.aws_iam_policy_document.ecs.json
}

data "aws_iam_policy_document" "ecs" {
  statement {
    actions = [
      "ssm:GetParameters",
      "secretmanager:GetSecretValue",
    ]

    resources = [for parameter in aws_ssm_parameter.for_ecs : parameter.arn]
  }
}
