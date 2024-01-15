# Allows Lambda to assume an IAM role

data "aws_iam_policy_document" "merge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create IAM execution role for Merge function

resource "aws_iam_role" "role_for_merge" {
  name               = "role_for_merge"
  assume_role_policy = data.aws_iam_policy_document.merge_assume_role.json
}

# Set policy for Merge function's role

data "aws_iam_policy_document" "policy_doc_for_merge" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = ["*"]
  }
}

# Create policy for Merge function's role

resource "aws_iam_policy" "policy_for_merge" {
  name        = "policy_for_merge"
  description = "Policy for Merge function to upsert electricity price forecasts into the database on RDS"
  policy      = data.aws_iam_policy_document.policy_doc_for_merge.json
}

# Attach policy to role

resource "aws_iam_role_policy_attachment" "attach_policy_for_merge" {
  role       = aws_iam_role.role_for_merge.name
  policy_arn = aws_iam_policy.policy_for_merge.arn
}









# Set ECR repo for function

data "aws_ecr_repository" "merge" {
  name = "merge"
}

# Create Merge function

resource "aws_lambda_function" "merge" {
  function_name = "merge"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.merge.repository_url}:latest"
  role          = aws_iam_role.role_for_merge.arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_1_id, var.subnet_2_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.user_name
      PASSWORD  = var.password
    }
  }
}
