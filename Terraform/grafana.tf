# helm-grafana.tf
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  set {
    name  = "adminPassword"
    value = "admin"  # Set the Grafana admin password
  }

  set {
    name  = "service.type"
    value = "NodePort"  # Use NodePort or LoadBalancer based on your cluster setup
  }

  set {
    name  = "persistence.enabled"
    value = "false"  # Enable or disable persistent storage
  }
}
