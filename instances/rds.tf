#This tells your database which subnet it should stay. it is used incase you need when youre restoring your rds to an entirely different vpc and subnet
resource "aws_db_subnet_group" "db_subnet" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "DB Subnet Group"
  }
}