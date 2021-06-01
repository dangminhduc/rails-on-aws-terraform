data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

data "aws_elb_service_account" "alb" {}

data "aws_canonical_user_id" "current" {}

data "aws_caller_identity" "current" {}

locals {
  service_name = "rails-on-ecs"
  env          = "stg"
  prefix       = "${local.env}-${local.service_name}"

  rails_env  = "production"
  azs        = data.aws_availability_zones.available.names
  cidr       = "10.0.0.0/16"
  office_ips = ["1.2.3.4/32"]

  db_password       = "thisisdatabasepassword" # tfsec:ignore:GEN002 disable sensitive attribute check because this is a template project
  domain            = "dangminhduc.tk"
  domain_lb_app     = "${local.prefix}-app-lb.${local.domain}"
  cloudfront_domain = "dangminhduc.tk"
  domain_name_admin = "admin.dangminhduc.tk"
}
