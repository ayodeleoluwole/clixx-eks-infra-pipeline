provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.aws_region
}


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.clixx-app.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.clixx-app.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.clixx.token
  }
}
