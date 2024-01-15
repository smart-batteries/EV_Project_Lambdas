output "queue_url" {
  value = aws_sqs_queue.wits_data_queue.url
}

output "queue_arn" {
  value = aws_sqs_queue.wits_data_queue.arn
}

