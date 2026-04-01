
# Declare the data source for availablity zone
data "aws_availability_zones" "available" {
  state = "available"
}


data "aws_caller_identity" "current" {}


data "aws_vpc" "jenkins" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}


# Helm provider is needed to install AWS Load Balancer Controller
data "aws_eks_cluster_auth" "clixx" {
  name = aws_eks_cluster.clixx-app.name
}


data "tls_certificate" "clixx" {
  url = aws_eks_cluster.clixx-app.identity[0].oidc[0].issuer
}


# Fetch Jenkins instance details dynamically
data "aws_instance" "jenkins" {
  filter {
    name   = "tag:Name"
    values = ["Jenkins_server"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}