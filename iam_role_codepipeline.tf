resource "aws_iam_role" "codepipeline" {
  name               = "${local.prefix}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline.json
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.id
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_iam_policy" "codepipeline" {
  name   = "${local.prefix}-codepipeline"
  policy = data.aws_iam_policy_document.codepipeline.json
}

data "aws_iam_policy_document" "assume_codepipeline" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "codepipeline.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:CreateProject",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "codepipeline:GetPipelineExecution",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl", # OutputArtifactFormat": "CODE_ZIP" の場合に必要な権限
    ]

    resources = ["${aws_s3_bucket.codepipeline.arn}/*"]
  }

  # CodePipeline から GitHub v2 でコードを取得する権限
  statement {
    actions = [
      "codestar-connections:UseConnection",
    ]

    resources = [aws_codestarconnections_connection.main.arn]
  }

  # Artifact暗号化/復号用のKMSへのアクセス権限
  statement {
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]

    resources = [aws_kms_key.codepipeline.arn]
  }

  # NOTE: CodePipelineからCodeDeployを実行するのに必要な権限
  #       マネジメントコンソールからCodePipelineを作成する際に、同時に作成できるService Roleと、
  #       下記ドキュメントの記述を参考に作成。
  #       https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-custom-role
  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "ecs:RegisterTaskDefinition",
    ]

    resources = ["*"]
  }

  # NOTE: ECS へのデプロイ権限
  #       マネジメントコンソールからCodePipelineを作成する際に、同時に作成できるService Roleと、
  #       下記ドキュメントの記述を参考に作成。
  #       https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-custom-role
  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecr:DescribeImages"
    ]

    resources = ["*"] # TODO: 可能な限り resources を絞る
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.ecs.arn,
      aws_iam_role.ecs_task_app.arn,
      aws_iam_role.ecs_task_admin.arn,
    ]
  }
}
