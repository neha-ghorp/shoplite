variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type      = string
  sensitive = true
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version (https://artifacthub.io/packages/helm/argo/argo-cd)"
  type        = string
  default     = "7.8.0"
}

variable "server_node_port" {
  description = "NodePort for the ArgoCD UI (HTTP). Must match a kind port mapping to reach it from localhost"
  type        = number
  default     = 30081
}
