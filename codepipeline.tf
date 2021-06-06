# NOTE: data ソースがない為、PRD/STG で個々に connection を作成する
# see: https://github.com/hashicorp/terraform-provider-aws/issues/15453
resource "aws_codestarconnections_connection" "main" {
  name          = "connection-to-github"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "deploy" {
  name     = "${local.prefix}-deploy"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_alias.codepipeline.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      region           = "ap-northeast-1"
      version          = "1"
      output_artifacts = ["${local.prefix}-source"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.main.arn
        FullRepositoryId     = "medpeer-dev/resident-portal-rails"
        BranchName           = "develop"
        DetectChanges        = false # NOTE: コード変更検知トリガーを無効化。CI でテスト通過後、実行したい為。
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildWeb"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["${local.prefix}-source"]
      version          = "1"
      output_artifacts = ["${local.prefix}-build"]

      configuration = {
        ProjectName = aws_codebuild_project.web.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployApp"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["${local.prefix}-build"]
      version         = "1"

      # NOTE: https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements
      configuration = {
        ApplicationName                = aws_codedeploy_app.app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.app.deployment_group_name
        TaskDefinitionTemplateArtifact = "${local.prefix}-build"
        TaskDefinitionTemplatePath     = aws_s3_bucket_object.task_definition["app"].id
        AppSpecTemplateArtifact        = "${local.prefix}-build"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }

    action {
      name            = "DeployAdmin"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["${local.prefix}-build"]
      version         = "1"

      # NOTE: https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements
      configuration = {
        ApplicationName                = aws_codedeploy_app.admin.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.admin.deployment_group_name
        TaskDefinitionTemplateArtifact = "${local.prefix}-build"
        TaskDefinitionTemplatePath     = aws_s3_bucket_object.task_definition["admin"].id
        AppSpecTemplateArtifact        = "${local.prefix}-build"
        AppSpecTemplatePath            = "adminspec.yml"
      }
    }

    action {
      name            = "DeployWorker"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["${local.prefix}-build"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.worker.name
        FileName    = "imagedefinitions_worker.json"
      }
    }
  }
}
