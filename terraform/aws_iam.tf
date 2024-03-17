locals {
  aws_iam_role_name = "oidc_exp_aws_role"
  issuer_url        = "container.googleapis.com/v1/projects/${var.project_id}/locations/${var.zone}/clusters/oidc-exp-cluster"
}

resource "aws_iam_openid_connect_provider" "trusted_gke_cluster" {
  url             = "https://${local.issuer_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["08745487e891c19e3078c1f2a07e452950ef36f6"]
}

resource "aws_iam_role" "gcp_aws_federated_role" {
  name = local.aws_iam_role_name

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
            "${local.issuer_url}:sub" : "system:serviceaccount:default:oidc-exp-service-account",
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
  role       = aws_iam_role.gcp_aws_federated_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}
