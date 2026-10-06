# Shared by every unit. Each unit includes this with find_in_parent_folders("root.hcl").

# Local state, one file per unit under terragrunt/.state/<env>/<unit>/
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_parent_terragrunt_dir()}/.state/${path_relative_to_include()}/terraform.tfstate"
  }
}
