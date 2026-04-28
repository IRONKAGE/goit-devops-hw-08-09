resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = var.namespace
  create_namespace = true
  version          = "5.0.14"

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.adminPassword"
    value = "admin_password_123"
  }
}
