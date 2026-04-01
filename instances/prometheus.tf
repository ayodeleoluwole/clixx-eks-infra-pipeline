#===========================================================
# PROMETHEUS + GRAFANA + ALERTMANAGER
#===========================================================
resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_namespace
  create_namespace = true
  version          = var.kube_prometheus_stack_version
  timeout          = 600
  wait             = true

  # Jenkins metrics -- static scrape target since Jenkins lives outside kubernetes and its metrics is scraped by prometheus using /prometheus as the endpoint
  #The additionalPrometheusRulesMap is  rules for grafana, preomtehus and alert manager modified into value.yaml
  #The alertmanager block modifies alert settings for prometheus, grafana and alertmanager in value.yaml, and how the should be sent based on priority
  #note: that all the 3 blocks of values are put in values.yaml which is inside helms chart release created above
  values = [<<-EOT
    prometheus:
      prometheusSpec:
        additionalScrapeConfigs:
          - job_name: jenkins
            metrics_path: /prometheus
            static_configs:
              - targets: ["${data.aws_instance.jenkins.private_ip}:${var.jenkins_port}"]


    additionalPrometheusRulesMap:
      clixx-alert-rules:
        groups:
          - name: pod-alerts
            rules:
              - alert: PodCrashLooping
                expr: rate(kube_pod_container_status_restarts_total[5m]) * 60 > 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Pod is crash looping"
                  description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"

              - alert: "PodNotReady"
                expr: "kube_pod_status_ready{condition='false'} == 1"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "Pod not ready"
                  description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been not ready for 5 minutes"

              - alert: "PodOOMKilled"
                expr: "kube_pod_container_status_last_terminated_reason{reason='OOMKilled'} == 1"
                for: "1m"
                labels:
                  severity: critical
                annotations:
                  summary: "Pod OOM Killed"
                  description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} was OOM Killed"


          #Node alert            
          - name: "node-alerts"
            rules:            
              - alert: "NodeHighCPU"
                expr: "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode='idle'}[5m])) * 100) > 80"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "Node high CPU"
                  description: "Node {{ $labels.instance }} CPU usage is above 80%"
              
              - alert: "NodeHighMemory"
                expr: "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 80"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "Node high memory"
                  description: "Node {{ $labels.instance }} memory usage is above 80%"

              - alert: "NodeDiskPressure"
                expr: "node_filesystem_avail_bytes / node_filesystem_size_bytes * 100 < 20"
                for: "5m"
                labels:
                  severity: critical
                annotations:
                  summary: "Node low disk space"
                  description: "Node {{ $labels.instance }} has less than 20% disk space"

              - alert: "NodeNotReady"
                expr: "kube_node_status_condition{condition='Ready',status='true'} == 0"
                for: "5m"
                labels:
                  severity: critical
                annotations:
                  summary: "Node not ready"
                  description: "Node {{ $labels.node }} has been not ready for 5 minutes"


          #Application alert
          - name: app-alerts
            rules:
              - alert: DeploymentReplicasMismatch
                expr: kube_deployment_spec_replicas != kube_deployment_status_available_replicas
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Deployment replicas mismatch"
                  description: "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has fewer replicas than desired"


          #RDS alert          
          - name: "rds-alerts"
            rules:
              - alert: "RDSHighCPU"
                expr: "aws_rds_cpuutilization_average > 80"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "RDS high CPU"
                  description: "RDS instance clixx-retaildb-restore CPU is above 80%"

              - alert: "RDSLowStorage"
                expr: "aws_rds_free_storage_space_average < 5368709120"
                for: "5m"
                labels:
                  severity: critical
                annotations:
                  summary: "RDS low storage"
                  description: "RDS instance has less than 5GB storage remaining"

              - alert: "RDSHighConnections"
                expr: "aws_rds_database_connections_average > 80"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "RDS high connections"
                  description: "RDS instance has more than 80 active connections"

              - alert: "RDSHighReadLatency"
                expr: "aws_rds_read_latency_average > 0.1"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "RDS high read latency"
                  description: "RDS read latency is above 100ms"


          #Application load balancer alert
          - name: "alb-alerts"
            rules:
              - alert: "ALBHigh5xxErrors"
                expr: "aws_applicationelb_httpcode_elb_5_xx_count_sum > 10"
                for: "5m"
                labels:
                  severity: critical
                annotations:
                  summary: "ALB high 5xx error rate"
                  description: "ALB is returning more than 10 5xx errors in 5 minutes"

              - alert: "ALBHigh4xxErrors"
                expr: "aws_applicationelb_httpcode_elb_4_xx_count_sum > 50"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "ALB high 4xx error rate"
                  description: "ALB is returning more than 50 4xx errors in 5 minutes"

              - alert: "ALBHighResponseTime"
                expr: "aws_applicationelb_target_response_time_average > 2"
                for: "5m"
                labels:
                  severity: warning
                annotations:
                  summary: "ALB high response time"
                  description: "ALB average response time is above 2 seconds"

              - alert: "ALBUnhealthyHosts"
                expr: "aws_applicationelb_un_healthy_host_count_average > 0"
                for: "2m"
                labels:
                  severity: critical
                annotations:
                  summary: "ALB has unhealthy targets"
                  description: "ALB has unhealthy target pods — WordPress may be down"


    alertmanager:
      config:
        global:
          resolve_timeout: 5m
          slack_api_url: "${var.slack_webhook_url}"

        route:
          group_by:
            - alertname
            - namespace
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 12h
          receiver: slack-warnings
          routes:
            - match:
                severity: critical
              receiver: slack-critical

        receivers:
          - name: slack-warnings
            slack_configs:
              - channel: "#clixx-system-alert"
                send_resolved: true
                title: "{{ .GroupLabels.alertname }}"
                text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"

          - name: slack-critical
            slack_configs:
              - channel: "#clixx-system-alert"
                send_resolved: true
                title: "CRITICAL: {{ .GroupLabels.alertname }}"
                text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"

  EOT
  ]

  #grafana settings
  set {
    name  = "grafana.enabled"
    value = "true"
  }
  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "%(protocol)s://%(domain)s/grafana"
  }
  set {
    name  = "grafana.grafana\\.ini.server.serve_from_sub_path"
    value = "true"
  }

  # Alertmanager settings
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }
  set {
    name  = "alertmanager.service.type"
    value = "ClusterIP"
  }

  #Prometheus settings
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }

  depends_on = [
    aws_eks_node_group.clixxretail,
    helm_release.alb_controller
  ]
  
}
