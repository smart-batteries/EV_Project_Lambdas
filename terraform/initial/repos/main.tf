resource "aws_ecr_repository" "repos" {
  count = length(var.names)

  name                 = var.names[count.index]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}