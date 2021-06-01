resource "aws_ssm_parameter" "for_ecs" {
  for_each = {
    "master_key"           = "Rails Master Key"
    "database_url"         = "Database URL"
    "database_replica_url" = "Replica URL"
    "datadog_api_key"      = "Datadog API Key"
    "github_oauth_token"   = "GitHub OAuth Token"
    "redis_url"            = "Redis URL"
  }

  name = "/${local.service_name}/${local.env}/${each.key}"
  type = "SecureString"
  # value       = data.aws_kms_secrets.secrets.plaintext[each.key]
  value       = local.secrets[each.key]
  description = each.value
}
