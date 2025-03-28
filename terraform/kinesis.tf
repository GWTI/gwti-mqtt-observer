# Kinesis Stream
resource "aws_kinesis_stream" "data_stream" {
  name        = "${var.SERVICE}-${var.STAGE}-DataStream"
  shard_count = 1 # Adjust based on throughput needs
}

# IoT Rule to forward MQTT to Kinesis
resource "aws_iot_topic_rule" "kinesis_rule" {
  name        = replace("${var.SERVICE}_${var.STAGE}_IotToKinesisRule", "-", "_")
  enabled     = true
  sql         = "SELECT * FROM 'mqtt/topic'"
  sql_version = "2016-03-23"

  kinesis {
    stream_name   = aws_kinesis_stream.data_stream.name
    partition_key = "$${timestamp()}" # Dynamic partition key
    role_arn      = aws_iam_role.iot_kinesis_role.arn
  }
}
