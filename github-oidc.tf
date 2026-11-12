# Exists once per account, already there: look it up.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "service_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:atilla/service-code:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_service" {
  name               = "${var.name}-gha-service"
  assume_role_policy = data.aws_iam_policy_document.service_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.hello.arn]
  }
}

resource "aws_iam_role_policy" "gha_service" {
  name   = "${var.name}-gha-service"
  role   = aws_iam_role.gha_service.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

data "aws_iam_policy_document" "infra_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:atilla/infra-code:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_infra" {
  name               = "${var.name}-gha-infra"
  assume_role_policy = data.aws_iam_policy_document.infra_trust.json
}

resource "aws_iam_role_policy_attachment" "gha_infra_admin" {
  role       = aws_iam_role.gha_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "gha_infra_ecr" {
  name   = "${var.name}-gha-infra-ecr"
  role   = aws_iam_role.gha_infra.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

data "aws_iam_policy_document" "infra_plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:atilla/infra-code:pull_request"]
    }
  }
}

resource "aws_iam_role" "gha_infra_plan" {
  name               = "${var.name}-gha-infra-plan"
  assume_role_policy = data.aws_iam_policy_document.infra_plan_trust.json
}

data "aws_iam_policy_document" "infra_plan" {
  statement {
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ecr:DescribeRepositories",
      "eks:DescribeAccessEntry",
      "eks:DescribeAccessPolicy",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:ListAccessEntries",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListTagsForResource",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::atilla-csk-w10-tfstate"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::atilla-csk-w10-tfstate"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["infra-code/*"]
    }
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::atilla-csk-w10-tfstate/infra-code/terraform.tfstate.tflock"
    ]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::atilla-csk-w10-tfstate/infra-code/terraform.tfstate"]
  }
}

resource "aws_iam_role_policy" "gha_infra_plan" {
  name   = "${var.name}-gha-infra-plan"
  role   = aws_iam_role.gha_infra_plan.id
  policy = data.aws_iam_policy_document.infra_plan.json
}

resource "aws_eks_access_entry" "gha_infra" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.gha_infra.arn
}

resource "aws_eks_access_policy_association" "gha_infra" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.gha_infra.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "gha_infra_plan" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.gha_infra_plan.arn
}

resource "aws_eks_access_policy_association" "gha_infra_plan" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.gha_infra_plan.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  access_scope {
    type = "cluster"
  }
}
