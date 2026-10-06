# Connects to the cluster using credentials passed in from the kind-cluster module
# (wired together by Terragrunt's `dependency` block).
provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    client_certificate     = var.client_certificate
    client_key             = var.client_key
  }
}
