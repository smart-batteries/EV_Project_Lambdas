# Create user request API

resource "aws_apigatewayv2_api" "user_request" {
  description   = "API where end-users request a model run"
  name          = "user_request"
  protocol_type = "HTTP"
  target        = var.start_pipeline_arn
}

# Grant the user api permission to invoke the start_pipeline function

resource "aws_lambda_permission" "allow_request" {
    statement_id  = "AllowInvokeFromUserRequestAPI"
    action        = "lambda:InvokeFunction"
    function_name = var.start_pipeline_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.user_request.execution_arn}/*"
}

# Set route for users to request a model run

resource "aws_apigatewayv2_route" "run_request_route" {
  api_id    = aws_apigatewayv2_api.user_request.id
  route_key = "GET /run"
  target    = "integrations/${aws_apigatewayv2_integration.run_request_integration.id}"
}

# Integrate user run request with the start_pipeline function

resource "aws_apigatewayv2_integration" "run_request_integration" {
  description            = "User requests for a model run are sent to the start_pipeline function"
  api_id                 = aws_apigatewayv2_api.user_request.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.start_pipeline_invoke_arn
  payload_format_version = "2.0"
}






# Create user result API

resource "aws_apigatewayv2_api" "user_result" {
  description   = "API where end-users retrieve their result from the model"
  name          = "user_result"
  protocol_type = "HTTP"
  target        = var.return_result_arn
}

# Grant the user api permission to invoke the return_result function

resource "aws_lambda_permission" "allow_retrieval" {
    statement_id  = "AllowInvokeFromUserRetrievalAPI"
    action        = "lambda:InvokeFunction"
    function_name = var.return_result_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.user_result.execution_arn}/*"
}

# Set route for users to retrieve results

resource "aws_apigatewayv2_route" "result_route" {
  api_id    = aws_apigatewayv2_api.user_result.id
  route_key = "GET /result"
  target    = "integrations/${aws_apigatewayv2_integration.result_integration.id}"
}

# Integrate user result retrieval with the return_result function

resource "aws_apigatewayv2_integration" "result_integration" {
  description            = "User retrieval of model results are sent to the return_result function"
  api_id                 = aws_apigatewayv2_api.user_result.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.return_result_invoke_arn
  payload_format_version = "2.0"
}