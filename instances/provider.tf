provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.clixx-app.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.clixx-app.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.clixx.token
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.clixx-app.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.clixx-app.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.clixx.token
}