resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    configs = {
      params = {
        # Serve the UI over plain HTTP - fine for a local kind cluster
        "server.insecure" = true
      }
    }
    server = {
      service = {
        type         = "NodePort"
        nodePortHttp = var.server_node_port
      }
    }
    # Not needed locally; keeps the footprint small
    dex           = { enabled = false }
    notifications = { enabled = false }
  })]
}
