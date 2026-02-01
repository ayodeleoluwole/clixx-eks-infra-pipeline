output "vpc_id" {
  value = aws_vpc.clixx-vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}


output "cluster_name" {
  value = aws_eks_cluster.clixx-app.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.clixx-app.endpoint
}


output "ecr_repository_url" {
  value = aws_ecr_repository.clixx_retail_repository.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.clixx_retail_repository.name
}



output "rds_sg_id" {
  value = aws_security_group.rds-sg.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.db_subnet.name
}


output "aws_account_id" {
  description = "Used to construct ECR login endpoint in deployment pipeline"
  value       = data.aws_caller_identity.current.account_id
}
