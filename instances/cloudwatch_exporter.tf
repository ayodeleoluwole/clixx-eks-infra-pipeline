#===========================================================
# CLOUDWATCH EXPORTER
# Pulls RDS and ALB metrics from CloudWatch into Prometheus
#===========================================================
resource "helm_release" "cloudwatch_exporter" {
  name       = "cloudwatch-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-cloudwatch-exporter"
  namespace  = var.monitoring_namespace
  version    = "0.25.3"
  timeout    = 300
  wait       = true

  values = [<<-EOT
    aws:
      region: ${var.aws_region}

    serviceAccount:
      create: true
      name: cloudwatch-exporter
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.cloudwatch_exporter.arn}

    config: |-
      region: ${var.aws_region}
      metrics:
        - aws_namespace: AWS/RDS
          aws_metric_name: CPUUtilization
          aws_dimensions: [DBInstanceIdentifier]
          aws_statistics: [Average]
        - aws_namespace: AWS/RDS
          aws_metric_name: FreeStorageSpace
          aws_dimensions: [DBInstanceIdentifier]
          aws_statistics: [Average]
        - aws_namespace: AWS/RDS
          aws_metric_name: DatabaseConnections
          aws_dimensions: [DBInstanceIdentifier]
          aws_statistics: [Average]
        - aws_namespace: AWS/RDS
          aws_metric_name: ReadLatency
          aws_dimensions: [DBInstanceIdentifier]
          aws_statistics: [Average]
        - aws_namespace: AWS/ApplicationELB
          aws_metric_name: RequestCount
          aws_dimensions: [LoadBalancer]
          aws_statistics: [Sum]
        - aws_namespace: AWS/ApplicationELB
          aws_metric_name: TargetResponseTime
          aws_dimensions: [LoadBalancer]
          aws_statistics: [Average]
        - aws_namespace: AWS/ApplicationELB
          aws_metric_name: HTTPCode_ELB_5XX_Count
          aws_dimensions: [LoadBalancer]
          aws_statistics: [Sum]
        - aws_namespace: AWS/ApplicationELB
          aws_metric_name: HTTPCode_ELB_4XX_Count
          aws_dimensions: [LoadBalancer]
          aws_statistics: [Sum]
        - aws_namespace: AWS/ApplicationELB
          aws_metric_name: UnHealthyHostCount
          aws_dimensions: [LoadBalancer, TargetGroup]
          aws_statistics: [Average]
    EOT
  ]

  depends_on = [
    helm_release.kube_prometheus_stack,
    aws_iam_role_policy_attachment.cloudwatch_exporter
  ]
}