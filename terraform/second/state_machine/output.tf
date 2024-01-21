output "state_machine_arn" {
  value = aws_sfn_state_machine.problems_pipeline_state_machine.arn
}