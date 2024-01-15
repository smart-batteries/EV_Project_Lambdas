# Allows Lambda to assume an IAM role

data "aws_iam_policy_document" "lambda_assume_role" {
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

resource "aws_iam_role" "role_for_prss_prsl" {
  name               = "role_for_prss_prsl"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


# Set policy for PRSS & PRSL functions' role

data "aws_iam_policy_document" "policy_doc_for_prss_prsl" {
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

# Create policy for PRSS & PRSL functions' role

resource "aws_iam_policy" "policy_for_prss_prsl" {
  name        = "policy_for_prss_prsl"
  description = "Policy for PRSS & PRSL functions to call the WITS API for electricity price forecasts"
  policy      = data.aws_iam_policy_document.policy_doc_for_prss_prsl.json
}

# Attach policy to role

resource "aws_iam_role_policy_attachment" "attach_policy_for_prss_prsl" {
  role       = aws_iam_role.role_for_prss_prsl.name
  policy_arn = aws_iam_policy.policy_for_prss_prsl.arn
}





# Set ECR repos for functions

data "aws_ecr_repository" "prss" {
  name = "prss"
}

data "aws_ecr_repository" "prsl" {
  name = "prsl"
}


# Create PRSS function

resource "aws_lambda_function" "prss" {
  function_name = "prss"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prss.repository_url}:latest"
  role          = aws_iam_role.role_for_prss_prsl.arn
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
    }
  }
}

# Create PRSL function

resource "aws_lambda_function" "prsl" {
  function_name = "prsl"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prsl.repository_url}:latest"
  role          = aws_iam_role.role_for_prss_prsl.arn
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
    }
  }
}





# Allow EventBridge schedules to trigger invocation of PRSS & PRSL functions

resource "aws_cloudwatch_event_target" "trigger_prss_function" {
    rule = var.prss_schedule_name
    target_id = "prss"
    arn = aws_lambda_function.prss.arn
}


resource "aws_cloudwatch_event_target" "trigger_prsl_function" {
    rule = var.prsl_schedule_name
    target_id = "prsl"
    arn = aws_lambda_function.prsl.arn
}

