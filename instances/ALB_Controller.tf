# AWS LOAD BALANCER CONTROLLER
# Installed via Helm into the cluster
# This is what creates the ALB when the deployment pipeline applies the Ingress YAML

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.clixx-app.name
  }
  

  set {
    name  = "vpcId"
    value = aws_vpc.clixx-vpc.id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  depends_on = [
    aws_eks_node_group.clixxretail,
    aws_iam_openid_connect_provider.clixx
  ]
}