include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/terraform/modules//argocd"
}

# ArgoCD needs the cluster to exist first; Terragrunt orders `run --all` by this.
dependency "cluster" {
  config_path = "../kind-cluster"

  # Lets `plan`/`validate` work before the cluster has been created
  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock"
    client_certificate     = "mock"
    client_key             = "mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  cluster_endpoint       = dependency.cluster.outputs.endpoint
  cluster_ca_certificate = dependency.cluster.outputs.cluster_ca_certificate
  client_certificate     = dependency.cluster.outputs.client_certificate
  client_key             = dependency.cluster.outputs.client_key
  server_node_port       = local.env.argocd_node_port
}
