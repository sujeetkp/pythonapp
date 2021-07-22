# Global Variables
aws_region = "us-west-2"
department = "tech"
environment = "dev"

# VPC Variables
vpc_cidr_block = "10.0.0.0/16"
vpc_public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
vpc_private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
vpc_single_nat_gateway = true

# EKS Cluster Variables
eks_cluster_version = "1.20"
eks_desired_worker_nodes = 2
eks_max_worker_nodes = 2
eks_min_worker_nodes = 2
eks_worker_instance_type = "t3.small"
eks_worker_root_volume_size = "8"
eks_worker_key_pair = "us-west-2-keypair"
eks_worker_root_volume_type = "gp2"

# Bastion Host
bastion_host_instance_type = "t2.micro"
bastion_host_key_pair = "us-west-2-keypair"