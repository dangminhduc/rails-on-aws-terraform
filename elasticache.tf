resource "aws_elasticache_subnet_group" "redis" {
  name        = "${local.prefix}-redis-subnet-group"
  description = "${local.prefix}-redis-subnet-group"
  subnet_ids  = aws_subnet.elasticache.*.id
}

resource "aws_elasticache_parameter_group" "redis" {
  name        = "${local.prefix}-redis-pg"
  description = "${local.prefix}-redis-pg"
  family      = "redis6.x"
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${local.prefix}-redis-rg"
  replication_group_description = "${local.prefix}-redis-rg"
  node_type                     = "cache.t3.micro"
  number_cache_clusters         = 1
  engine                        = "redis"
  engine_version                = "6.x"
  maintenance_window            = "sat:20:00-sat:21:00"
  parameter_group_name          = aws_elasticache_parameter_group.redis.name
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.redis.id]
  auto_minor_version_upgrade    = false
  transit_encryption_enabled    = false # tfsec:ignore:AWS036 hiredisが対応しないため、無効にします。
  at_rest_encryption_enabled    = true

  tags = {
    Name = "${local.prefix}-redis-rg"
    Env  = local.env
  }
}
