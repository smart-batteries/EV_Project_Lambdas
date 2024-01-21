# Create user API

resource "aws_apigatewayv2_api" "user_api" {
  description   = "API where end-users request a model run and the model results"
  name          = "user_api"
  protocol_type = "HTTP"
  target        = var.start_pipeline_arn
}

# Grant the user api permission to invoke the start_pipeline function

resource "aws_lambda_permission" "allow_api" {
    statement_id  = "AllowInvokeFromUserRequestAPI"
    action        = "lambda:InvokeFunction"
    function_name = var.start_pipeline_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.user_api.execution_arn}/*"
}




# Set route for user run requests

resource "aws_apigatewayv2_route" "run_request_route" {
  api_id    = aws_apigatewayv2_api.user_api.id
  route_key = "GET /run"
  target    = "integrations/${aws_apigatewayv2_integration.run_request_integration.id}"
}

# Integrate user run request with the start_pipeline function

resource "aws_apigatewayv2_integration" "run_request_integration" {
  description            = "Integrate user request API with the start_pipeline function"
  api_id                 = aws_apigatewayv2_api.user_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.start_pipeline_invoke_arn
  payload_format_version = "2.0"
}








# Set route for api tests

resource "aws_apigatewayv2_route" "test_route" {
  api_id    = aws_apigatewayv2_api.user_api.id
  route_key = "GET /test"
  target    = "integrations/${aws_apigatewayv2_integration.test_integration.id}"
}

# Integrate user run request with the start_pipeline function

resource "aws_apigatewayv2_integration" "test_integration" {
  description            = "Integrate api test calls with the sandpit1 function"
  api_id                 = aws_apigatewayv2_api.user_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = "arn:aws:lambda:eu-north-1:133433735071:function:sandpit1"
  payload_format_version = "2.0"
}





# Set route for user result requests

# resource "aws_apigatewayv2_route" "result_request_route" {
#   api_id    = aws_apigatewayv2_api.user_api.id
#   route_key = "GET /result"
#   target    = "integrations/${aws_apigatewayv2_integration.result_request_integration.id}"
# }

# Integrate user result request with the start_pipeline function

# resource "aws_apigatewayv2_integration" "result_request_integration" {
#   description            = ""
#   api_id                 = aws_apigatewayv2_api.user_api.id
#   integration_type       = "AWS_PROXY"
#   connection_type        = "INTERNET"
#   integration_method     = "POST"
#   integration_uri        = 
#   payload_format_version = "2.0"
# }





