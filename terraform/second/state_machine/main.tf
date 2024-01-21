# Set the CloudWatch log group of the Step Functions state machine

data "aws_cloudwatch_log_group" "problems_pipeline_state_machine" {
  name = "/aws/vendedlogs/states/problems_pipeline_state_machine"
}


# Create the Step Functions state machine

resource "aws_sfn_state_machine" "problems_pipeline_state_machine" {
  name     = "problems_pipeline_state_machine"
  type     = "EXPRESS"
  role_arn = var.state_machine_role_arn

  definition = <<EOF
{
  "Comment": "Execute the lambda functions of the problems pipeline",
  "StartAt": "log_request",
  "States": {
    "log_request": {
      "Type": "Task",
      "Resource": "${var.log_request_arn}",
      "InputPath": "$.user_request",
      "Next": "create_problem"
    },
    "create_problem": {
      "Type": "Task",
      "Resource": "${var.create_problem_arn}",
      "InputPath": "$.full_request",
      "Next": "get_prices"
    },
    "get_prices": {
      "Type": "Task",
      "Resource": "${var.get_prices_arn}",
      "InputPath": "$.prob_id",
      "Next": "solver"
    },
    "solver": {
      "Type": "Task",
      "Resource": "${var.solver_arn}",
      "InputPath": "$.run_id",
      "End": true
    }
  }
}
EOF

  logging_configuration {
    log_destination        = "${data.aws_cloudwatch_log_group.problems_pipeline_state_machine.arn}:*"
    level                  = "ALL"
    include_execution_data = true
  }
}