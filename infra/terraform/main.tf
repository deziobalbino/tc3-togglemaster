locals {
  common_tags = {
    Project     = "fase3"
    Environment = "lab"
    Owner       = "lucas"
  }
}

data "aws_iam_role" "eks_cluster_role" {
  name = var.eks_cluster_role_name
}

data "aws_iam_role" "eks_node_role" {
  name = var.eks_node_role_name
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = var.vpc_name
  })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.vpc_name}-public-a"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.vpc_name}-public-b"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(local.common_tags, {
    Name                              = "${var.vpc_name}-private-a"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.az_b

  tags = merge(local.common_tags, {
    Name                              = "${var.vpc_name}-private-b"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-a"
  })
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_b_cidr
  availability_zone = var.az_b

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-b"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-nat"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-private-rt"
  })
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.vpc_name}-eks-cluster-sg"
  description = "Security group do cluster EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS interno para API do cluster"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Saida liberada"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-eks-cluster-sg"
  })
}

resource "aws_security_group" "rds_auth_sg" {
  name        = "${var.vpc_name}-rds-auth-sg"
  description = "Security group do RDS do auth-service"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL a partir da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-rds-auth-sg"
  })
}

resource "aws_db_subnet_group" "auth" {
  name = "${var.cluster_name}-auth-db-subnet-group"

  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-auth-db-subnet-group"
  })
}

resource "aws_db_instance" "auth" {
  identifier             = "${var.cluster_name}-auth-db"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = var.auth_db_instance_class
  allocated_storage      = 20
  db_name                = var.auth_db_name
  username               = var.auth_db_username
  password               = var.auth_db_password
  db_subnet_group_name   = aws_db_subnet_group.auth.name
  vpc_security_group_ids = [aws_security_group.rds_auth_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-auth-db"
  })
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.private_a.id, aws_subnet.private_b.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_route_table_association.public_a,
    aws_route_table_association.public_b,
    aws_route_table_association.private_a,
    aws_route_table_association.private_b
  ]

  tags = merge(local.common_tags, {
    Name = var.cluster_name
  })
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  depends_on = [aws_eks_cluster.main]

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-ng"
  })
}

resource "aws_db_instance" "flag" {
  identifier             = "${var.cluster_name}-flag-db"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = var.flag_db_instance_class
  allocated_storage      = 20
  db_name                = var.flag_db_name
  username               = var.flag_db_username
  password               = var.flag_db_password
  db_subnet_group_name   = aws_db_subnet_group.auth.name
  vpc_security_group_ids = [aws_security_group.rds_auth_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-flag-db"
  })
}

resource "aws_db_instance" "targeting" {
  identifier             = "${var.cluster_name}-targeting-db"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = var.targeting_db_instance_class
  allocated_storage      = 20
  db_name                = var.targeting_db_name
  username               = var.targeting_db_username
  password               = var.targeting_db_password
  db_subnet_group_name   = aws_db_subnet_group.auth.name
  vpc_security_group_ids = [aws_security_group.rds_auth_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-targeting-db"
  })
}

resource "aws_sqs_queue" "evaluation_events" {
  name = "${var.cluster_name}-evaluation-events"

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-evaluation-events"
  })
}

resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "ToggleMasterAnalytics"
  })
}