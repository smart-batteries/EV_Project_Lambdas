# Create queue that will ferry data from PRSS & PRSL to Merge function

resource "aws_sqs_queue" "wits_data_queue" {
  name                      = "wits_data_queue"
  visibility_timeout_seconds = 60
  message_retention_seconds = 1800

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.wits_dead_queue.arn
    maxReceiveCount     = 4
  })
}

# Create its dead-letter queue

resource "aws_sqs_queue" "wits_dead_queue" {
  name = "wits_dead_queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.wits_dead_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.wits_data_queue.arn]
  })
}
