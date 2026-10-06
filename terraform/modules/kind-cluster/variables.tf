variable "cluster_name" {
  description = "Name of the kind cluster (kubectl context becomes kind-<name>)"
  type        = string
}

variable "node_image" {
  description = "kindest/node image to use, e.g. kindest/node:v1.31.2. null = provider default"
  type        = string
  default     = null
}

variable "port_mappings" {
  description = "Host -> kind node port mappings, used to reach NodePort services from localhost"
  type = list(object({
    host_port      = number
    container_port = number
  }))
  default = []
}
