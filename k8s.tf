data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_namespace_v1" "hello" {
  metadata {
    name = "hello"
  }

  depends_on = [aws_eks_node_group.default]
}

/*
# Step 4, once the cluster exists:
resource "kubernetes_manifest" "deployment" {
  manifest = yamldecode(file("${path.module}/k8s/deployment.yaml"))

  depends_on = [ kubernetes_namespace_v1.hello ]
}
*/
