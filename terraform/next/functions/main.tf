# Allows Lambda to assume an IAM role

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}



# Create IAM execution role for PRSS & PRSL functions

resource "aws_iam_role" "WITS_call_function_role" {
  name               = "WITS_call_function_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}



# Set policy for role

data "aws_iam_policy_document" "WITS_call_function_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "sqs:SendMessage"
    ]
    resources = ["*"]
  }
}



# Create policy for role

resource "aws_iam_policy" "WITS_call_function_policy" {
  name        = "WITS_call_function_policy"
  description = "Policy for PRSS & PRSL functions to call the WITS API for electricity price forecasts"
  policy      = data.aws_iam_policy_document.WITS_call_function_policy.json
}



# Attach policy to role

resource "aws_iam_role_policy_attachment" "WITS_call_function_attach" {
  role       = aws_iam_role.WITS_call_function_role.name
  policy_arn = aws_iam_policy.WITS_call_function_policy.arn
}



# Set ECR repo for function

data "aws_ecr_repository" "prss" {
  name = "prss"
}

data "aws_ecr_repository" "prsl" {
  name = "prsl"
}


# Create PRSS function

resource "aws_lambda_function" "PRSS" {
  function_name = "PRSS"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prss.repository_url}:latest"
  role          = aws_iam_role.WITS_call_function_role.arn
  handler       = "lambda_function.lambda_handler"
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
    }
  }
}

# Create PRSL function

resource "aws_lambda_function" "PRSL" {
  function_name = "PRSL"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prsl.repository_url}:latest"
  role          = aws_iam_role.WITS_call_function_role.arn
  handler       = "lambda_function.lambda_handler"
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
    }
  }
}