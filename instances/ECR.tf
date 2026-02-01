resource "aws_ecr_repository" "clixx_retail_repository" {
  name                 = "${var.project}-repository"
  image_tag_mutability = "MUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project}-ecr"
    Environment = var.environment
  }
}


resource "aws_ecr_lifecycle_policy" "clixx" {
  repository = aws_ecr_repository.clixx_retail_repository.name
  policy = jsonencode({
  rules = [{
    rulePriority = 1
    description  = "Keep only last 2 images"
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = 2
    }
    action = { type = "expire" }
  }]
})
}