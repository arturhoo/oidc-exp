data "tls_certificate" "cert" {
  url = aws_eks_cluster.primary.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.primary.identity[0].oidc[0].issuer

  tags = {
    Name = "oidc-exp-cluster-eks-irsa",
  }
}

locals {
  gke_issuer_url = "container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_zone}/clusters/oidc-exp-cluster"
}

resource "aws_iam_openid_connect_provider" "trusted_gke_cluster" {
  url             = "https://${local.gke_issuer_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["08745487e891c19e3078c1f2a07e452950ef36f6"]
}

locals {
  eks_issuer = trimprefix(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://")
}

resource "aws_iam_role" "federated_role" {
  name = "oidc_exp_federated_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.trusted_gke_cluster.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.gke_issuer_url}:sub" : "system:serviceaccount:default:oidc-exp-service-account",
          }
        }
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.oidc_provider.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.eks_issuer}:aud" : "sts.amazonaws.com",
            "${local.eks_issuer}:sub" : "system:serviceaccount:default:oidc-exp-service-account"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name = "s3_read_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_policy_attachment" {
  role       = aws_iam_role.federated_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}
