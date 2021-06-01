resource "aws_db_subnet_group" "db_subnet" {
  name        = "${local.prefix}-db-subnet"
  description = "${local.prefix}-db-subnet"
  subnet_ids  = aws_subnet.rds.*.id

  tags = {
    Name = "${local.prefix}-db-subnet"
    Env  = local.env
  }
}

resource "aws_db_parameter_group" "aurora_mysql" {
  name   = "${local.prefix}-aurora-mysql"
  family = "aurora-mysql5.7"

  tags = {
    Name = "${local.prefix}-aurora-mysql"
    Env  = local.env
  }

  parameter {
    name         = "long_query_time"
    value        = "5"
    apply_method = "immediate"
  }

  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "immediate"
  }

  # NOTE: aurora default sql_mode is not set.
  # So to avoid difference from local environment, it should be be change to mysql 5.7 default sql_mode
  # More info at: https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html
  # https://www.tcmobile.jp/dev_blog/%E6%9C%AA%E5%88%86%E9%A1%9E/rds-aurora-%E3%81%AE-sql_mode-%E3%81%8C%E3%83%87%E3%83%95%E3%82%A9%E3%83%AB%E3%83%88%E5%80%A4%E3%81%AB%E6%88%BB%E3%81%9B%E3%81%AA%E3%81%84/
  parameter {
    name         = "sql_mode"
    value        = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_mysql" {
  name        = "${local.prefix}-aurora-mysql"
  family      = "aurora-mysql5.7"
  description = "${local.prefix}-aurora-mysql"


  parameter {
    name         = "character_set_client"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_filesystem"
    value        = "binary"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_bin"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_bin"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  }

  tags = {
    Name = local.prefix
    Env  = local.env
  }
}

resource "aws_rds_cluster" "rds_cluster" {
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.09.2"
  cluster_identifier = "${local.prefix}-cluster"
  master_username    = "root"
  # master_password                 = data.aws_kms_secrets.secrets.plaintext["db_password"]
  #NOTE: should be encrypted with KMS
  master_password                 = local.db_password # tfsec:ignore:GEN003 disable sensitive attribute check because this is a template project
  backup_retention_period         = 14
  preferred_backup_window         = "18:00-18:30"
  preferred_maintenance_window    = "sat:20:00-sat:21:00"
  port                            = 3306
  skip_final_snapshot             = true
  vpc_security_group_ids          = [aws_security_group.mysql.id]
  db_subnet_group_name            = aws_db_subnet_group.db_subnet.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql.name
  enabled_cloudwatch_logs_exports = ["slowquery"]
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  deletion_protection             = true

  tags = {
    Name = "${local.prefix}-db-cluster"
    Env  = local.env
  }
}

resource "aws_rds_cluster_instance" "rds_cluster_instance" {
  count                      = 1
  engine                     = "aurora-mysql"
  identifier                 = "${local.prefix}-db${count.index}"
  cluster_identifier         = aws_rds_cluster.rds_cluster.id
  instance_class             = "db.t3.small"
  db_subnet_group_name       = aws_db_subnet_group.db_subnet.name
  db_parameter_group_name    = aws_db_parameter_group.aurora_mysql.name
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  monitoring_interval        = 60
  apply_immediately          = false
  auto_minor_version_upgrade = false
  ca_cert_identifier         = "rds-ca-2019"

  tags = {
    Name = "${local.prefix}-db${count.index}"
    Env  = local.env
  }
}
