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

# Allows Step Functions to assume an IAM role

data "aws_iam_policy_document" "step_func_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}






# Create IAM execution role for PRSS & PRSL functions
resource "aws_iam_role" "wits_execution_role" {
  name               = "wits_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Set permissions policy for PRSS & PRSL functions' role

data "aws_iam_policy_document" "wits_permissions" {
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

# Create permissions policy for PRSS & PRSL functions' role

resource "aws_iam_policy" "wits_policy" {
  name        = "wits_policy"
  description = "Policy for PRSS & PRSL functions to call the WITS API for electricity price forecasts"
  policy      = data.aws_iam_policy_document.wits_permissions.json
}

# Attach permissions policy to PRSS & PRSL functions' role

resource "aws_iam_role_policy_attachment" "attach_wits_policy" {
  role       = aws_iam_role.wits_execution_role.name
  policy_arn = aws_iam_policy.wits_policy.arn
}






# Create IAM execution role for Merge function

resource "aws_iam_role" "merge_execution_role" {
  name               = "merge_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Set permissions policy for Merge function's role

data "aws_iam_policy_document" "merge_permissions" {
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
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = ["*"]
  }
}

# Create permissions policy for Merge function's role

resource "aws_iam_policy" "merge_policy" {
  name        = "merge_policy"
  description = "Policy for Merge function to upsert electricity price forecasts into the database on RDS"
  policy      = data.aws_iam_policy_document.merge_permissions.json
}

# Attach permissions policy to Merge function's role

resource "aws_iam_role_policy_attachment" "attach_merge_policy" {
  role       = aws_iam_role.merge_execution_role.name
  policy_arn = aws_iam_policy.merge_policy.arn
}






# Create IAM execution role for start_pipeline function

resource "aws_iam_role" "start_pipeline_role" {
  name               = "start_pipeline_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Set permissions policy for the execution role

data "aws_iam_policy_document" "start_pipeline_permissions" {
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
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "states:StartExecution"
    ]
    resources = ["*"]
  }
}

# Create permissions policy for the start_pipeline role

resource "aws_iam_policy" "start_pipeline_policy" {
  name        = "start_pipeline_policy"
  description = "Policy for start_pipeline function to trigger the state machine"
  policy      = data.aws_iam_policy_document.start_pipeline_permissions.json
}

# Attach permissions policy to execution role

resource "aws_iam_role_policy_attachment" "attach_start_pipeline_policy" {
  role       = aws_iam_role.start_pipeline_role.name
  policy_arn = aws_iam_policy.start_pipeline_policy.arn
}






# Create an IAM execution role for the Step Functions state machine

resource "aws_iam_role" "state_machine_execution_role" {
  name               = "state_machine_execution_role"
  assume_role_policy = data.aws_iam_policy_document.step_func_assume_role.json
}

# Set permissions policy for the state machine's role

data "aws_iam_policy_document" "state_machine_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogDelivery",
      "logs:ListLogDeliveries",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "lambda:InvokeFunction"
    ]
    resources = ["*"]
  }
}

# Create permissions policy for the execution role

resource "aws_iam_policy" "state_machine_policy" {
  name        = "state_machine_policy"
  description = "Policy for the state machine to invoke the lambda functions of the problems pipeline"
  policy      = data.aws_iam_policy_document.state_machine_permissions.json
}

# Attach permissions policy to execution role

resource "aws_iam_role_policy_attachment" "attach_state_machine_policy" {
  role       = aws_iam_role.state_machine_execution_role.name
  policy_arn = aws_iam_policy.state_machine_policy.arn
}






# Create an IAM execution role for the other lambda functions

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Set permissions policy for the execution role

data "aws_iam_policy_document" "lambda_permissions" {
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
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

# Create permissions policy for the execution role

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for function to interact with the database on RDS & solver model"
  policy      = data.aws_iam_policy_document.lambda_permissions.json
}

# Attach permissions policy to execution role

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
