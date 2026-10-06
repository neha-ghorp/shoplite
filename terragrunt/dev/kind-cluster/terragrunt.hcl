include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/terraform/modules//kind-cluster"
}

inputs = {
  cluster_name = local.env.cluster_name

  port_mappings = [
    { host_port = local.env.frontend_host_port, container_port = local.env.frontend_node_port },
    { host_port = local.env.argocd_host_port, container_port = local.env.argocd_node_port },
  ]
}
