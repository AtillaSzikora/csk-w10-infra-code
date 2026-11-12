output "service_role_arn" {
  value = aws_iam_role.gha_service.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.hello.repository_url
}

# + infra_role_arn, and the update-kubeconfig command
output "infra_role_arn" {
  value = aws_iam_role.gha_infra.arn
}

output "infra_plan_role_arn" {
  value = aws_iam_role.gha_infra_plan.arn
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name} --role-arn ${aws_iam_role.gha_infra.arn}"
}
