# Create the VPC
resource "aws_vpc" "clixx-vpc" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    tags = {
        Name            = "${var.project}-vpc"
        Environment     = var.environment
        }
}

# Create a public subnet
resource "aws_subnet" "public" {
    count                   = 2
    vpc_id                  = aws_vpc.clixx-vpc.id
    cidr_block              = cidrsubnet(aws_vpc.clixx-vpc.cidr_block, 8, count.index)
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    
    tags = {
        Name                = "${var.project}-PublicSubnet_${count.index}"
        }
        
}


# Create a private subnet
resource "aws_subnet" "private" {
    count                   = 2
    vpc_id                  = aws_vpc.clixx-vpc.id
    cidr_block              = cidrsubnet(aws_vpc.clixx-vpc.cidr_block, 8, count.index + 2)  #(The +2 here means it will start using cidr creation from 2, this is becaause 0 and 1 has been used by public subnet e.g 10.0.2.0/24,  10.0.3.0/24 )
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = false # Instances launched into this subnet get a private IP
    
    tags = {
        Name                = "${var.project}-PrivateSubnet_${count.index}"
        }
        
}


# Create an Internet Gateway (to route public subnet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.clixx-vpc.id

  tags = {
    Name = "${var.project}-igw"
  }
}



# Create Elastic IPs for the NAT gateways (this is the public ip assigned to the nat gatway which the private subnet will mount on, inother to access the internet)
resource "aws_eip" "nat" {
  count  = 2 # One EIP per NAT Gateway
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip_${count.index}" }
}


# Create NAT gateways (You have to create 2 nat gways to route private subnet as each subnet can only mount a single nat gway and not a single nat on multiple subnet)
resource "aws_nat_gateway" "nat" {
  count         = 2                     #The two counts means for the 2 private subnets created
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # NAT GW lives in a public subnet

  tags = {
    Name        = "${var.project}-nat-gateway-${count.index}" #The +1 mean it will start its count from 1
  }

}



# Create a Public Route Table (We ony need a single route table in a public subnet. That is because multiple subnets can mount on a single route table)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.clixx-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name       = "${var.project}-public-route-table"
  }

  lifecycle {
    ignore_changes = [route]
  }
}

# Associate Public Subnets with Public Route Table #This means i am assigning 1 route table to each public subnet
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Create a Private Route Table for each AZ (a private subnet needs a route table per subnet. This is because of nat gateway which is only applicabe to a subnet)
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.clixx-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id # Route traffic through the respective NAT GW
  }

  tags = {
    Name = "private-route-table-${count.index}"
  }

lifecycle {
    ignore_changes = [route]
  }
}

# Associate Private Subnets with Private Route Tables
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


####################################################################################################
#Add  vpc peering between my private vpc and the jenkins vpc
####################################################################################################
#VPC peering allows two VPCs to communicate with each other using private IP addresses, as if they were in the same network.

#This tells your private subnets: "if you receive a response destined for 172.31.0.0/16 (Jenkins VPC), send it back through the peering connection." Without this, RDS would receive the connection from Jenkins but wouldn't know how to send the response back
resource "aws_vpc_peering_connection" "jenkins_to_app" {
  vpc_id      = data.aws_vpc.jenkins.id    # requester (Jenkins VPC)
  peer_vpc_id = aws_vpc.clixx-vpc.id       # accepter (App VPC)
  auto_accept = true                       # automatically accept the request

  tags = {
    Name      = "${var.project}-jenkins-to-app-peering"
  }
}


#Same as Resource 2 but for the public subnets. Adds the return route so any resource in the public subnet can also respond back to Jenkins.
#Private route table
resource "aws_route" "app_to_jenkins" {
  count                     = 2
  route_table_id            = aws_route_table.private[count.index].id
  destination_cidr_block    = data.aws_vpc.jenkins.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.jenkins_to_app.id
}

#Public route table
resource "aws_route" "app_to_jenkins_public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.jenkins.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.jenkins_to_app.id
}