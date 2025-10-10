# provider "aws" {
#   region = "us-west-2" # 修改为你的区域
# }

# # ---------------------------
# # VPC
# # ---------------------------
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "main-vpc"
#   }
# }

# # ---------------------------
# # Subnet (准备作为公有子网)
# # ---------------------------
# resource "aws_subnet" "subnet1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-west-2a"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public-subnet-1a"
#   }
# }

# # ---------------------------
# # Internet Gateway
# # ---------------------------
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main-igw"
#   }
# }

# # ---------------------------
# # Route Table (公有)
# # ---------------------------
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "public-rt"
#   }
# }

# # 路由条目: 让 0.0.0.0/0 流量走 IGW
# resource "aws_route" "public_internet_access" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.igw.id
# }

# # ---------------------------
# # Route Table Association
# # ---------------------------
# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.subnet1.id
#   route_table_id = aws_route_table.public.id
# }

# # 安全组
# resource "aws_security_group" "ecs_sg" {
#   vpc_id = aws_vpc.main.id
#   ingress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     self      = true
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # ECS Cluster
# resource "aws_ecs_cluster" "main" {
#   name = "demo-cluster"
# }

# data "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"
# }


# # Task Definition
# resource "aws_ecs_task_definition" "app" {
#   family                   = "demo-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"

#   execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

#   container_definitions = jsonencode([
#     {
#       name      = "demo-app"
#       image     = "nginx:latest" # 替换为你自己的镜像
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ]
#     }
#   ])
# }

# # ECS Service
# resource "aws_ecs_service" "app" {
#   name            = "demo-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.app.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets          = [aws_subnet.subnet1.id]
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }
# }

# resource "aws_ecs_service" "mono-engine" {
#   name            = "mono-engine-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.app.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets          = [aws_subnet.subnet1.id]
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }
# }


# # ---------------------------
# # PostgreSQL RDS
# # ---------------------------
# resource "aws_db_subnet_group" "pg_subnet_group" {
#   name       = "pg-subnet-group"
#   subnet_ids = ["subnet-xxxxxx", "subnet-yyyyyy"]  # 替换你的子网 ID

#   tags = {
#     Name = "pg-subnet-group"
#   }
# }

# resource "aws_db_instance" "postgres" {
#   identifier         = "demo-postgres"
#   engine             = "postgres"
#   engine_version     = "15.3"
#   instance_class     = "db.t3.micro"   # 根据需求选大小
#   allocated_storage  = 20
#   storage_type       = "gp2"
#   username           = "pgadmin"
#   password           = "PgAdmin123!"  # 可以用 terraform var 或 AWS Secrets Manager
#   db_name            = "demo_db"
#   multi_az           = false
#   publicly_accessible = true           # 如果想在公网访问设置 true
#   vpc_security_group_ids = ["sg-xxxxxxxx"]  # 允许 ECS 访问
#   db_subnet_group_name   = aws_db_subnet_group.pg_subnet_group.name
#   skip_final_snapshot    = true

#   tags = {
#     Name = "demo-postgres"
#   }
# }

# # ---------------------------
# # MySQL RDS
# # ---------------------------
# resource "aws_db_subnet_group" "mysql_subnet_group" {
#   name       = "mysql-subnet-group"
#   subnet_ids = ["subnet-xxxxxx", "subnet-yyyyyy"]

#   tags = {
#     Name = "mysql-subnet-group"
#   }
# }

# resource "aws_db_instance" "mysql" {
#   identifier         = "demo-mysql"
#   engine             = "mysql"
#   engine_version     = "8.0"
#   instance_class     = "db.t3.micro"
#   allocated_storage  = 20
#   storage_type       = "gp2"
#   username           = "mysqladmin"
#   password           = "MysqlAdmin123!"
#   db_name            = "demo_db"
#   multi_az           = false
#   publicly_accessible = true
#   vpc_security_group_ids = ["sg-xxxxxxxx"]
#   db_subnet_group_name   = aws_db_subnet_group.mysql_subnet_group.name
#   skip_final_snapshot    = true

#   tags = {
#     Name = "demo-mysql"
#   }
# }