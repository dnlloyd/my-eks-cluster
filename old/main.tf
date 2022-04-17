variable "cluster_name" {
  default = "k8sEksLab"
  type = string
}

variable "vpc_id" {
  default = "vpc-065b33a8baa73e2a3"
  type = string
}

resource "aws_iam_role" "eks_cluster_mgmt" {
  name = "EksClusterMgmt"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster_mgmt.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_mgmt.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_mgmt.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_mgmt.name
}

resource "aws_eks_cluster" "k8s_lab" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_mgmt.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    subnet_ids = ["subnet-08090a8df7f3a8c63", "subnet-07f0c07531ff40032", "subnet-0377599577dac9845"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_cloudwatch_log_group.example
  ]
}

resource "aws_eks_node_group" "k8s_lab" {
  cluster_name = aws_eks_cluster.k8s_lab.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn = aws_iam_role.eks_cluster_mgmt.arn
  subnet_ids = ["subnet-08090a8df7f3a8c63", "subnet-07f0c07531ff40032", "subnet-0377599577dac9845"]
  instance_types = ["t3.micro"]

  scaling_config {
    desired_size = 3
    max_size = 3
    min_size = 3
  }

  update_config {
    max_unavailable = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}

resource "aws_cloudwatch_log_group" "example" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

output "endpoint" {
  value = aws_eks_cluster.k8s_lab.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.k8s_lab.certificate_authority[0].data
}
