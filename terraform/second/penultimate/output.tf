output "start_pipeline_arn" {
  value = aws_lambda_function.start_pipeline.arn
}

output "start_pipeline_name" {
  value = aws_lambda_function.start_pipeline.function_name
}

output "start_pipeline_invoke_arn" {
  value = aws_lambda_function.start_pipeline.invoke_arn
}

