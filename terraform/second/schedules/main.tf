# Allows EventBridge to assume an IAM role

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
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


resource "aws_scheduler_schedule" "prss_schedule" {
  name       = "prss_schedule"
  description = "Triggers call to WITS API for PRSS forecast data, every 30 min"

  state                        = "ENABLED"
  schedule_expression_timezone = "Pacific/Auckland"
  schedule_expression          = "cron(5,35 * * * ? *)"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 2
  }

  target {
    arn      = var.prss_arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}


resource "aws_scheduler_schedule" "prsl_schedule" {
  name       = "prsl_schedule"
  description = "Triggers call to WITS API for PRSL forecast data, every 2 hours"

  state                        = "ENABLED"
  schedule_expression_timezone = "Pacific/Auckland"
  schedule_expression          = "cron(15 */2 * * ? *)"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 2
  }

  target {
    arn      = var.prsl_arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}


resource "aws_scheduler_schedule" "purge_schedule" {
  name       = "purge_schedule"
  description = "Triggers a purge of the database, of outdated electricity price forecast data"

  state                        = "ENABLED"
  schedule_expression_timezone = "Pacific/Auckland"
  schedule_expression          = "cron(40 1 12 * ? *)"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 20
  }

  target {
    arn      = var.purge_arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
