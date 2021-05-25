# NOTE: aws_kms_secrets で terraform のコード中に暗号化した秘密情報を記述するための鍵
resource "aws_kms_key" "terraform" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "terraform" {
  name          = "alias/${local.prefix}-terraform"
  target_key_id = aws_kms_key.terraform.key_id
}

# data "aws_kms_secrets" "secrets" {

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
