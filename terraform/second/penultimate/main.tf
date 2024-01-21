# Allow the PRSS & PRSL functions to send messages to queue

resource "aws_sqs_queue_policy" "functions_send_message_policy" {
  queue_url = var.queue_url

  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${var.queue_arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": [
            "${var.prss_arn}",
            "${var.prsl_arn}"
          ]
        }
      }
    }
  ]
}
POLICY
}


# Allow the Merge function to receive messages from queue

resource "aws_lambda_event_source_mapping" "function_receive_message_policy" {
  event_source_arn = var.queue_arn
  function_name    = var.merge_arn
}


# Set ECR repo for the start_pipeline function

data "aws_ecr_repository" "start_pipeline" {
  name = "start_pipeline"
}

# Create start_pipeline function

resource "aws_lambda_function" "start_pipeline" {
  function_name = "start_pipeline"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.start_pipeline.repository_url}:latest"
  role          = var.start_pipeline_role_arn
  timeout       = 30

  environment {
    variables = {
      STATE_MACHINE_ARN = var.state_machine_arn
    }
  }
}

