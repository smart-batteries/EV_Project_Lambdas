output "prss_schedule_name" {
  value = aws_cloudwatch_event_rule.prss_schedule.id
}

output "prsl_schedule_name" {
  value = aws_cloudwatch_event_rule.prsl_schedule.id
}

output "purge_schedule_name" {
  value = aws_cloudwatch_event_rule.purge_schedule.id
}