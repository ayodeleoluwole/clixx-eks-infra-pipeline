
#========================================================================
# EKS Cluster security group
#========================================================================
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.project}-eks-cluster-sg"
  vpc_id      = aws_vpc.clixx-vpc.id
  description = "EKS cluster control plane security group"


  # outbound rule for eks cluster control plane to allow all outgoing traffic
  egress {
    from_port     = 0
    to_port       = 0
    protocol      = "-1"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-eks-cluster-sg" }
}


#========================================================================
# EKS worker nodes security group
#========================================================================
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.project}-eks-nodes-sg"
  vpc_id      = aws_vpc.clixx-vpc.id
  description = "EKS worker nodes security group"


  # inbound rule for EKS worker nodes for them to be able to communicate with each other 
  ingress {
    description = "Nodes communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }


    # inbound rule for EKS worker nodes for them to be able to communicate with each other 
  ingress {
    description = "control plane communicates with nodes"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }



  # outbound rule
  egress {
    from_port     = 0
    to_port       = 0
    protocol      = "-1"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-eks-nodes-sg" }

}


#========================================================================
# RDS security group
#========================================================================
resource "aws_security_group" "rds-sg" {
  vpc_id     = aws_vpc.clixx-vpc.id
  name       = "RDS-SG"
  description = "Allow RDS traffic from EKS SG only"


  # Allow EKS (port 3306) traffic ONLY from the Eks worker node security group
  ingress {
    security_groups = [aws_security_group.eks_nodes_sg.id]    #Instead of receiving traffuc from cidr_cidr_blocks =  ["0.0.0.0/0"] whch allows traffic from the internet
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    description     = "Allow MySQL from EKS worker nodes"  
  }


  # Allow Jenkins server to connect to RDS on port 3306.
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.jenkins.cidr_block]
    description = "Allow MySQL from Jenkins VPC"
  }

  #allow traffic from any pod running in the EKS cluster
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.clixx-app.vpc_config[0].cluster_security_group_id]
    description     = "Allow MySQL from EKS pods"
  }

  

  # Default egress to allow all outbound traffic
  egress {
    protocol      = "-1"
    from_port     = 0
    to_port       = 0
    cidr_blocks   = ["0.0.0.0/0"]
  }

}
