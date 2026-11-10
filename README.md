# infra-code

The infrastructure for the DevOps CSK CI/CD workshop: everything `service-code` needs to run, as
Terraform. Steps and hints: https://github.com/kohanyirobert/csk-w10-cicd

There is almost nothing here, on purpose: `main.tf` has the providers and the S3 backend, the two
workflows do nothing yet. Some files you could end up with:

| file | what goes in it | step |
|---|---|---|
| `network.tf` | VPC, two public subnets in two AZs, internet gateway, route table | 1 |
| `eks.tf` | the cluster and a node group, with their IAM roles | 1 |
| `ecr.tf` | the image repository | 1 |
| `github-oidc.tf` | the roles GitHub Actions assumes, and the cluster access for one of them | 1 |
| `k8s.tf` | the namespace; later the Deployment, read from `k8s/deployment.yaml` | 1, 4 |
| `outputs.tf` | what you need to copy elsewhere: role ARNs, ECR URL, kubeconfig command | 1 |
| `k8s/deployment.yaml` | the Deployment: which image, which tag, how many replicas | 4 |
| `.github/workflows/*.yml` | plan on PRs, apply on main | 5 |
