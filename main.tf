# ==========================================
# 1. Виклик модуля VPC
# ==========================================
module "vpc" {
  source             = "./modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr_block     = var.vpc_cidr
  public_subnets     = var.public_subnets_cidr
  private_subnets    = var.private_subnets_cidr
  availability_zones = var.availability_zones
  vpc_name           = "${var.project_name}-${var.environment}-vpc"
}

# ==========================================
# 2. Виклик модуля ECR
# ==========================================
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_repo_name
  scan_on_push = var.scan_on_push
}

# ==========================================
# 3. IAM Ролі для EKS (Обов'язково для AWS)
# ==========================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# ==========================================
# 4. Виклик модуля EKS
# ==========================================
# Виклик модуля EKS (Feature Toggle)
module "eks" {
  source = "./modules/eks"

  # Якщо enable_eks = false, Terraform просто проігнорує цей модуль
  count  = var.enable_eks ? 1 : 0

  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  subnet_ids                = module.vpc.private_subnet_ids

  cluster_role_arn          = aws_iam_role.eks_cluster_role.arn
  node_role_arn             = aws_iam_role.eks_node_role.arn

  node_instance_types       = var.node_instance_types
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  node_desired_size         = var.node_desired_size
  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}
