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




# Allow the PRSS & PRSL functions to send messages to queue

resource "aws_sqs_queue_policy" "functions_send_message_policy" {
  queue_url = aws_sqs_queue.wits_data_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.wits_data_queue.arn}",
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
  event_source_arn = aws_sqs_queue.wits_data_queue.arn
  function_name    = var.merge_arn
}
