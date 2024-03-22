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
  eks_issuer = trimprefix(aws_eks_cluster.primary.identity[0].oidc[0].issuer, "https://")
}

resource "aws_iam_role" "federated_role" {
  name = "oidc_exp_federated_role_aws"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
