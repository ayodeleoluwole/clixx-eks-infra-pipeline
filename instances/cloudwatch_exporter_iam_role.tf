#===========================================================
# CLOUDWATCH EXPORTER IAM ROLE
# Lets the CloudWatch exporter pod read RDS/ALB metrics via IRSA
#===========================================================
resource "aws_iam_policy" "cloudwatch_exporter" {
  name        = "${var.project}-cloudwatch-exporter-policy"
  description = "Read-only access to CloudWatch metrics for RDS and ALB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:GetMetricData",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "cloudwatch_exporter" {
  name = "${var.project}-cloudwatch-exporter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.clixx-app.identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.clixx-app.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.monitoring_namespace}:cloudwatch-exporter"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter.arn
}