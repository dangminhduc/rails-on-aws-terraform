# NOTE: aws_kms_secrets で terraform のコード中に暗号化した秘密情報を記述するための鍵
resource "aws_kms_key" "terraform" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "terraform" {
  name          = "alias/${local.prefix}-terraform"
  target_key_id = aws_kms_key.terraform.key_id
}

# NOTE: kms key for encrypting ecr docker images
resource "aws_kms_key" "ecr" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.prefix}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

resource "aws_kms_key" "cloudwatch_log" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "cloudwatch_log" {
  name          = "alias/${local.prefix}-cloudwatch-log"
  target_key_id = aws_kms_key.cloudwatch_log.key_id
}

# data "aws_kms_secrets" "secrets" {
# This is the place to put secret infomation such as database password, rails master key, etc
#  secret {
#    name = "db_password"
#    payload = "somethingbase64encoded"
#  }
# secret {
#   name    = "master_key"
#   payload = ""
# }

# secret {
#   name    = "database_url"
#   payload = ""
# }

# secret {
#   name    = "database_replica_url"
#   payload = ""
# }

# secret {
#   name    = "redis_url"
#   payload = ""
# }

# secret {
#   name    = "datadog_api_key"
#   payload = ""
# }

# secret {
#   name    = "aws_external_id_for_datadog"
#   payload = ""
# }

# secret {
#   name    = "github_oauth_token"
#   payload = ""
# }
# }

# NOTE: RDSのストレージ暗号化用のKMS鍵
resource "aws_kms_key" "rds" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# NOTE: CodePipelineのartifactの暗号化/復号に用いる鍵
resource "aws_kms_key" "codepipeline" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "codepipeline" {
  name          = "alias/${local.prefix}-codepipeline"
  target_key_id = aws_kms_key.codepipeline.key_id
}
