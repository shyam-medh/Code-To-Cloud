# Core Infrastructure Entrypoint

module "vpc" {
  source = "./modules/vpc"

  environment   = var.environment
  mgmt_vpc_cidr = var.mgmt_vpc_cidr
  prod_vpc_cidr = var.prod_vpc_cidr
}

module "tgw" {
  source = "./modules/tgw"

  environment = var.environment
  mgmt_vpc_id = module.vpc.mgmt_vpc_id
  prod_vpc_id = module.vpc.prod_vpc_id
  mgmt_subnets = module.vpc.mgmt_public_subnets
  prod_subnets = module.vpc.prod_private_app_subnets
}

module "security" {
  source = "./modules/security"

  environment   = var.environment
  mgmt_vpc_id   = module.vpc.mgmt_vpc_id
  prod_vpc_id   = module.vpc.prod_vpc_id
  mgmt_vpc_cidr = var.mgmt_vpc_cidr
}

module "nlb" {
  source = "./modules/nlb"

  environment           = var.environment
  prod_vpc_id           = module.vpc.prod_vpc_id
  public_subnets        = module.vpc.prod_public_subnets
  private_app_subnets   = module.vpc.prod_private_app_subnets
  public_nlb_sg_id      = module.security.public_nlb_sg_id
  internal_nlb_sg_id    = module.security.internal_nlb_sg_id
}

module "asg" {
  source = "./modules/asg"

  environment           = var.environment
  prod_vpc_id           = module.vpc.prod_vpc_id
  mgmt_vpc_id           = module.vpc.mgmt_vpc_id
  mgmt_subnets          = module.vpc.mgmt_public_subnets
  private_app_subnets   = module.vpc.prod_private_app_subnets
  public_subnets        = module.vpc.prod_public_subnets
  nginx_sg_id           = module.security.nginx_sg_id
  app_sg_id             = module.security.app_sg_id
  bastion_sg_id         = module.security.bastion_sg_id
  nginx_tg_arn          = module.nlb.nginx_tg_arn
  app_tg_arn            = module.nlb.app_tg_arn
  internal_nlb_dns      = module.nlb.internal_nlb_dns
}
