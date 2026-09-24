locals {
  env          = "dev"
  cluster_name = "shoplite-dev"

  # host port -> kind node port (NodePort services)
  frontend_host_port = 8080
  frontend_node_port = 30080
  argocd_host_port   = 8081
  argocd_node_port   = 30081
}
