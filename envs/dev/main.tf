locals {
  base_domain = "gitmega.dev"
  region      = "us-west-2"
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source              = "../../modules/vpc"
  vpc_cidr            = "10.0.0.0/16"
  region              = local.region
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

module "sg" {
  source = "../../modules/security_group"
  vpc_id = module.vpc.vpc_id
}

module "efs" {
  source     = "../../modules/efs"
  name       = "mono-efs"
  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = "10.0.0.0/16"
  subnet_ids = module.vpc.public_subnet_ids
}


module "acm" {
  source      = "../../modules/acm"
  domain_name = "*.${local.base_domain}"
}

module "alb" {
  source              = "../../modules/alb"
  name                = "mega-alb"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  acm_certificate_arn = module.acm.certificate_arn
  security_group_ids  = [module.sg.sg_id]
  target_groups = {
    mega_ui = {
      name              = "mega-ui"
      port              = 3000
      health_check_path = "/api/health"
    }
    campsite_api = {
      name              = "campsite-api"
      port              = 8080
      health_check_path = "/health"
    }
    mono_engine = {
      name              = "mono-engine"
      port              = 8000
      health_check_path = "/api/v1/status"
    }
    sync_server = {
      name              = "sync-server"
      port              = 9000
      health_check_path = "/"
    }
    orion_server = {
      name              = "orion-server"
      port              = 8004
      health_check_path = "/"
    }
  }
}


module "mono-engine" {
  source             = "../../modules/ecs"
  region             = local.region
  cluster_name       = "mega-app"
  task_family        = "mono-engine-task"
  container_name     = "app"
  container_image    = "public.ecr.aws/m8q5m4u3/mega:mono-0.1.0-pre-release"
  container_port     = 8000
  service_name       = "mono-engine"
  cpu                = "256"
  memory             = "512"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "MEGA_AUTHENTICATION__ENABLE_HTTP_PUSH",
      "value" : "true"
    },
    {
      "name" : "MEGA_BUILD__ENABLE_BUILD",
      "value" : "true"
    },
    {
      "name" : "MEGA_DATABASE__ACQUIRE_TIMEOUT",
      "value" : "3"
    },
    {
      "name" : "MEGA_DATABASE__CONNECT_TIMEOUT",
      "value" : "3"
    },
    {
      "name" : "MEGA_DATABASE__DB_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@${module.rds_pg.db_endpoint}/mono?sslmode=require"
    },
    {
      "name" : "MEGA_LOG__LEVEL",
      "value" : "info"
    },
  ]

  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["mono_engine"]
    container_name   = "app"
    container_port   = 8000
    host_headers     = ["git.${local.base_domain}"]
    priority         = 100
  }]
  alb_listener_arn = module.alb.https_listener_arn

  efs_volume = {
    name           = "volumn1"
    file_system_id = module.efs.file_system_id
    root_directory = "/"
  }
  mount_points = [
    {
      containerPath = "/opt/mega/vault"
      readOnly      = false
      sourceVolume  = "volumn1"
    },
    {
      containerPath = "/opt/mega/etc"
      readOnly      = false
      sourceVolume  = "volumn1"
    }
  ]
}

module "mega-ui-app" {
  source             = "../../modules/ecs"
  region             = local.region
  cluster_name       = "mega-app"
  task_family        = "mega-ui-task"
  container_name     = "app"
  container_image    = "public.ecr.aws/m8q5m4u3/mega:mega-ui-staging-0.1.0-pre-release"
  container_port     = 3000
  service_name       = "mega-ui-service"
  cpu                = "512"
  memory             = "1024"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
  environment        = []
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["mega_ui"]
    container_name   = "app"
    container_port   = 3000
    host_headers     = ["app.${local.base_domain}"]
    priority         = 200
  }]
  alb_listener_arn = module.alb.https_listener_arn
}

module "mega-web-sync-app" {
  source             = "../../modules/ecs"
  region             = local.region
  cluster_name       = "mega-app"
  task_family        = "mega-web-sync-task"
  container_name     = "app"
  container_image    = "public.ecr.aws/m8q5m4u3/mega:mega-web-sync-server-0.1.0-pre-release"
  container_port     = 9000
  service_name       = "mega-web-sync-service"
  cpu                = "512"
  memory             = "1024"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "APP_ENV",
      "value" : "development"
    },
    {
      "name" : "NEXT_PUBLIC_SYNC_URL",
      "value" : "ws://sync.${local.base_domain}"
    },
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["sync_server"]
    container_name   = "app"
    container_port   = 9000
    host_headers     = ["sync.${local.base_domain}"]
    priority         = 300
  }]
  alb_listener_arn = module.alb.https_listener_arn
}


module "orion-server-app" {
  source             = "../../modules/ecs"
  region             = local.region
  cluster_name       = "mega-app"
  task_family        = "orion-server-task"
  container_name     = "app"
  container_image    = "public.ecr.aws/m8q5m4u3/mega:orion-server-0.1.0-pre-release"
  container_port     = 8004
  service_name       = "orion-server-service"
  cpu                = "512"
  memory             = "1024"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "MONOBASE_URL",
      "value" : "https://git.${local.base_domain}"
    },
    {
      "name" : "BUILD_LOG_DIR",
      "value" : "/tmp/megadir/buck2ctl"
    },
    {
      "name" : "DATABASE_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@${module.rds_pg.db_endpoint}/mono"
    },
    {
      "name" : "PORT",
      "value" : "8004"
    },
    {
      "name" : "ALLOWED_CORS_ORIGINS",
      "value" : "http://local.${local.base_domain}, https://app.${local.base_domain}, http://app.gitmono.test"
    }
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["orion_server"]
    container_name   = "app"
    container_port   = 8004
    host_headers     = ["orion.${local.base_domain}"]
    priority         = 400
  }]
  alb_listener_arn = module.alb.https_listener_arn
}


module "campsite-api-app" {
  source             = "../../modules/ecs"
  region             = local.region
  cluster_name       = "mega-app"
  task_family        = "campsite-api-task"
  container_name     = "app"
  container_image    = "public.ecr.aws/m8q5m4u3/mega:campsite-0.1.0-pre-release"
  container_port     = 8080
  service_name       = "campsite-api-service"
  cpu                = "1024"
  memory             = "2048"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "DEV_APP_URL",
      "value" : "http://app.${local.base_domain}"
    },
    {
      "name" : "PORT",
      "value" : "8080"
    },
    {
      "name" : "RAILS_ENV",
      "value" : "staging"
    },
    {
      "name" : "RAILS_MASTER_KEY",
      "value" : "694e02a56ba2e954fe1200d804e916ac"
    },
    {
      "name" : "SERVER_COMMAND",
      "value" : "bundle exec puma"
    }
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["campsite_api"]
    container_name   = "app"
    container_port   = 8080
    host_headers     = ["api.${local.base_domain}", "auth.${local.base_domain}"]
    priority         = 500
  }]
  alb_listener_arn = module.alb.https_listener_arn

}


module "rds_pg" {
  source              = "../../modules/rds"
  engine              = "postgres"
  engine_version      = "17"
  identifier          = "mega-app-postgres"
  instance_class      = "db.t4g.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = var.db_username
  password            = var.db_password
  db_name             = "mono"
  publicly_accessible = true
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [module.sg.sg_id]
}


# module "rds_mysql" {
#   source             = "../../modules/rds"
#   engine             = "mysql"
#   engine_version     = "8.0"
#   identifier         = "campsite-mysql"
#   instance_class     = "db.t4g.micro"
#   allocated_storage  = 20
#   storage_type       = "gp2"
#   username            = var.db_username
#   password            = var.db_password
#   db_name            = "demo_db"
#   publicly_accessible = true
#   subnet_ids         = [module.vpc.public_subnet_ids]
#   security_group_ids = [module.sg.sg_id]
# }


output "pg_endpoint" {
  value = module.rds_pg.db_endpoint
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
