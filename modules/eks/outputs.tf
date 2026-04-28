output "cluster_name" {
  description = "Назва створеного EKS кластера"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Ендпоінт кластера"
  value       = aws_eks_cluster.main.endpoint
}
