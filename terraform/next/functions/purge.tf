# Allows Lambda to assume an IAM role

data "aws_iam_policy_document" "purge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Create IAM execution role for Purge function

resource "aws_iam_role" "role_for_purge" {
  name               = "role_for_purge"
  assume_role_policy = data.aws_iam_policy_document.purge_assume_role.json
}

# Set policy for Purge function's role

data "aws_iam_policy_document" "policy_doc_for_purge" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

# Create policy for Purge function's role

resource "aws_iam_policy" "policy_for_purge" {
  name        = "policy_for_purge"
  description = "Policy for Purge function to purge the database on RDS of outdated electricity price forecasts"
  policy      = data.aws_iam_policy_document.policy_doc_for_purge.json
}

# Attach policy to role

resource "aws_iam_role_policy_attachment" "attach_policy_for_purge" {
  role       = aws_iam_role.role_for_purge.name
  policy_arn = aws_iam_policy.policy_for_purge.arn
}









# Set ECR repo for function

data "aws_ecr_repository" "purge" {
  name = "purge"
}

# Create Purge function

resource "aws_lambda_function" "purge" {
  function_name = "purge"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.purge.repository_url}:latest"
  role          = aws_iam_role.role_for_purge.arn
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


# Allow EventBridge schedules to trigger invocation of Purge function

resource "aws_cloudwatch_event_target" "trigger_purge_function" {
    rule = var.purge_schedule_name
    target_id = "purge"
    arn = aws_lambda_function.purge.arn
}

