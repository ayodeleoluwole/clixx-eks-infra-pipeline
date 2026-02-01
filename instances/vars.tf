variable "AWS_ACCESS_KEY" {} 
variable "AWS_SECRET_KEY" {}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "test_instances_kp.pub"
}


variable "ami_id" {
  default="ami-0b671272c81662a99"
}

variable "ami_type" {
  default = "AL2023_x86_64_STANDARD"
}


variable "node_instance_type"{
  default="t3.medium"
}


variable "project" {
  type    = string
  default = "clixx-retail"
}


variable "environment" {
  type    = string
  default = "development"
}


variable "cluster_name" {
  type    = string
  default = "clixx-eks-cluster"
}


variable "kubernetes_version" {
  type    = string
  default = "1.31"
}


variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}


variable "node_desired_size" {
  type    = number
  default = 2
}


variable "node_min_size" {
  type    = number
  default = 1
}


variable "node_max_size" {
  type    = number
  default = 4
}