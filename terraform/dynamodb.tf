resource "aws_dynamodb_table" "observer_zip_table" {
  name         = "${var.SERVICE}-${var.STAGE}-RawObserverDataTable" # Aligned with expected name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "timestamp"
  range_key    = "datasource"

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "datasource"
    type = "S"
  }

  attribute {
    name = "sent"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  global_secondary_index {
    name               = "DataSourceIndex"
    hash_key           = "datasource"
    range_key          = "timestamp"
    projection_type    = "INCLUDE"
    non_key_attributes = ["sent"]
  }

  global_secondary_index {
    name            = "SentIndex"
    hash_key        = "sent"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "devkey_cache_table" {
  name         = "${var.SERVICE}-${var.STAGE}-DevKeyCache"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "serial"
  range_key    = "address"

  attribute {
    name = "serial"
    type = "S"
  }

  attribute {
    name = "address"
    type = "S"
  }
  tags = {
    Name = "${var.SERVICE}-${var.STAGE}-DevKeyCache"
  }
}

resource "aws_dynamodb_table" "observer_m_messages" {
  name         = "${var.SERVICE}-${var.STAGE}-ObserverMMessages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "messageId"

  attribute {
    name = "messageId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  global_secondary_index {
    name            = "TimestampIndex"
    hash_key        = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Environment = "${var.STAGE}"
    Purpose     = "Observer M Message Storage"
  }
}
