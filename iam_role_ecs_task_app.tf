# タスク実行に必要な基本的なpolicy
data "aws_iam_policy_document" "ecs_task_assume_role" {
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

resource "aws_iam_role" "ecs_task_app" {
  name               = "${local.prefix}-ecs-task-app"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}
