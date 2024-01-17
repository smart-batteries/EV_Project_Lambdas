
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








# Create user API

resource "aws_apigatewayv2_api" "user_api" {
  description   = "API where end-users request a model run and the model results"
  name          = "user_api"
  protocol_type = "HTTP"
  target        = var.log_request_arn
}

# Set route for user run requests

resource "aws_apigatewayv2_route" "run_request_route" {
  api_id    = aws_apigatewayv2_api.user_api.id
  route_key = "run"
  target    = "integrations/${aws_apigatewayv2_integration.run_request_integration.id}"
}

# Integrate user run request with the log_request function

resource "aws_apigatewayv2_integration" "run_request_integration" {
  description            = "Integrate user request API with the log_request function"
  api_id                 = aws_apigatewayv2_api.user_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.log_request_invoke_arn
  payload_format_version = "2.0"
}


# Grant the user api permission to invoke the log_request function

resource "aws_lambda_permission" "allow_api" {
    statement_id  = "AllowInvokeFromUserRequestAPI"
    action        = "lambda:InvokeFunction"
    function_name = var.log_request_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.user_api.execution_arn}/*"
}



# Set route for user result requests

# resource "aws_apigatewayv2_route" "result_request_route" {
#   api_id    = aws_apigatewayv2_api.user_api.id
#   route_key = "result"
#   target    = "integrations/${aws_apigatewayv2_integration.result_request_integration.id}"
# }

# Integrate user run request with the log_request function

# resource "aws_apigatewayv2_integration" "result_request_integration" {
#   description            = ""
#   api_id                 = aws_apigatewayv2_api.user_api.id
#   integration_type       = "AWS_PROXY"
#   connection_type        = "INTERNET"
#   integration_method     = "POST"
#   integration_uri        = 
#   payload_format_version = "2.0"
# }










