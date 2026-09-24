output "namespace" {
  value = helm_release.argocd.namespace
}

output "chart_version" {
  value = helm_release.argocd.version
}

output "admin_password_command" {
  description = "Run this to get the initial admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
