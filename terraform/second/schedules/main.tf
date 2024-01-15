# Allows EventBridge to assume an IAM role

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}


# Create IAM execution role for EventBridge scheduler

resource "aws_iam_role" "scheduler_role" {
  name               = "scheduler_role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}


# Set policy for role

data "aws_iam_policy_document" "scheduler_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = ["*"]
  }
}


# Create policy for role

resource "aws_iam_policy" "scheduler_policy" {
  name        = "scheduler_policy"
  description = "Policy for EventBridge schedules to trigger invocation of PRSS, PRSL & Purge functions"
  policy      = data.aws_iam_policy_document.scheduler_policy.json
}


# Attach policy to role

resource "aws_iam_role_policy_attachment" "scheduler_role_policy_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}









# Create schedules that will trigger PRSS, PRSL, Purge functions

resource "aws_cloudwatch_event_rule" "prss_schedule" {
  name        = "prss_schedule"
  description = "Triggers call to WITS API for PRSS, every 30 min"

  role_arn = aws_iam_role.scheduler_role.arn
  schedule_expression = "cron(5,35 * * * ? *)"
}

resource "aws_cloudwatch_event_rule" "prsl_schedule" {
  name        = "prsl_schedule"
  description = "Triggers call to WITS API for PRSL, every 2 hours"

  role_arn = aws_iam_role.scheduler_role.arn
  schedule_expression = "cron(15 */2 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "purge_schedule" {
  name        = "purge_schedule"
  description = "Triggers a purge of the database, of outdated electricity price forecast data"

  role_arn = aws_iam_role.scheduler_role.arn
  schedule_expression = "cron(40 1 12 * ? *)"
}


