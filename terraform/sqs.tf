resource "aws_sqs_queue" "mqtt_message_queue" {
  name                       = "${var.SERVICE}-${var.STAGE}-MQTTMessageQueue"
  delay_seconds              = 0
  message_retention_seconds  = 86400 # 1 day retention
  visibility_timeout_seconds = 300   # Match Lambda timeout
}
