data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_role" {
  name                  = "oidc-exp-cluster-role"
  assume_role_policy    = data.aws_iam_policy_document.cluster_assume_role_policy.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "cluster_policy_attachment" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_resource_controller_policy_attachment" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_security_group" "cluster_sg" {
  name   = "oidc-exp-cluster-sg"
  vpc_id = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster_sg_rule" {
  description              = "Node group to cluster API"
  security_group_id        = aws_security_group.cluster_sg.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group_sg.id
}

resource "aws_eks_cluster" "primary" {
  name     = "oidc-exp-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.29"

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids              = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
    security_group_ids      = [aws_security_group.cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy_attachment,
    aws_iam_role_policy_attachment.vpc_resource_controller_policy_attachment,
    aws_security_group.cluster_sg,
  ]
}

data "aws_iam_policy_document" "node_group_assume_role_policy" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_group_role" {
  name                  = "oidc-exp-node-group-role"
  assume_role_policy    = data.aws_iam_policy_document.node_group_assume_role_policy.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "worker_node_policy_attachment" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_policy_attachment" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cni_policy_attachment" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_security_group" "node_group_sg" {
  name   = "oidc-exp-node-group-sg"
  vpc_id = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "kubernetes.io/cluster/oidc-exp-cluster" = "owned"
  }
}

resource "aws_security_group_rule" "cluster_to_node_group_sg_rule" {
  description              = "Cluster API to node groups"
  security_group_id        = aws_security_group.node_group_sg.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "cluster_to_kubelets_sg_rule" {
  description              = "Cluster API to node kubelets"
  security_group_id        = aws_security_group.node_group_sg.id
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "node_to_node_coredns_sg_rule" {
  description       = "Node to node CoreDNS"
  security_group_id = aws_security_group.node_group_sg.id
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "node_to_node_coredns_udp_sg_rule" {
  description       = "Node to node CoreDNS"
  security_group_id = aws_security_group.node_group_sg.id
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "egress_sg_rule" {
  description       = "Allow all egress"
  security_group_id = aws_security_group.node_group_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
}

resource "aws_launch_template" "launch_template" {
  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.node_group_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      "k8s.io/cluster-autoscaler/enabled"          = true
      "k8s.io/cluster-autoscaler/oidc-exp-cluster" = "owned"
    }
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = {
      "k8s.io/cluster-autoscaler/enabled"          = true
      "k8s.io/cluster-autoscaler/oidc-exp-cluster" = "owned"
    }
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name  = aws_eks_cluster.primary.name
  node_role_arn = aws_iam_role.node_group_role.arn
  subnet_ids    = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.default_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  ami_type       = "BOTTLEROCKET_ARM_64"
  instance_types = ["t4g.small"]

  depends_on = [
    aws_iam_role_policy_attachment.cni_policy_attachment,
    aws_iam_role_policy_attachment.ec2_container_registry_policy_attachment,
    aws_iam_role_policy_attachment.worker_node_policy_attachment,
  ]
}

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
