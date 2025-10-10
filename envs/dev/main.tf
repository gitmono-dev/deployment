provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source              = "../../modules/vpc"
  vpc_cidr            = "10.0.0.0/16"
  region              = "us-west-2"
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


#EC2 实例挂载 EFS
module "ec2" {
  source        = "../../modules/ec2"
  name          = "efs-editor"
  ami           = "ami-0caa91d6b7bee0ed0" ## Amazon Linux 2023（内核-6.1）
  instance_type = "t2.micro"
  subnet_ids    = module.vpc.public_subnet_ids
  vpc_id        = module.vpc.vpc_id
  efs_id        = module.efs.file_system_id
  mount_point   = "/mnt/efs"
  efs_sg_id     = module.efs.security_group_id
}



module "mono-engine" {
  source             = "../../modules/ecs"
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
  environment        = []

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
}

module "mega-web-sync-app" {
  source             = "../../modules/ecs"
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
      "value" : "ws://sync.gitmega.com"
    },
  ]
}


module "orion-server-app" {
  source             = "../../modules/ecs"
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
      "value" : "https://git.gitmega.com"
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
      "value" : "http://local.gitmega.com, https://app.gitmega.com, http://app.gitmono.test"
    }
  ]
  mount_points = []
}


module "campsite-api-app" {
  source             = "../../modules/ecs"
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
      "value" : "http://app.gitmega.com"
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

output "ec2_ip" {
  value = module.ec2.public_ip
}

output "pg_endpoint" {
  value = module.rds_pg.db_endpoint
}
