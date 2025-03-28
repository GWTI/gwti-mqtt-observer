provider "aws" {
  region = var.REGION
}

terraform {
  backend "s3" {
    bucket = "gwti-mqtt-observer-terraform-state"
    key    = "eu-west-2/gwti-mqtt-observer/${var.STAGE}/terraform.tfstate" # Dynamic key based on STAGE
    region = "eu-west-2"
  }
}

data "aws_vpc" "existing_vpc_1" {
  filter {
    name   = "tag:Name"
    values = ["IM-VPC"]
  }
}

data "aws_subnet" "selected_a" {
  filter {
    name   = "tag:Name"
    values = ["IM-Public-SNa"]
  }
}

data "aws_subnet" "selected_b" {
  filter {
    name   = "tag:Name"
    values = ["IM-Public-SNb"]
  }
}

resource "aws_security_group" "send_data_sg" {
  name        = "${var.SERVICE}-${var.STAGE}-SendTelemetryDataSG" # Aligned with earlier naming
  description = "Security group for sendObserverData Lambda allowing outbound HTTPS traffic"
  vpc_id      = data.aws_vpc.existing_vpc_1.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.SERVICE}-${var.STAGE}-SendTelemetryDataSG"
  }
}



resource "aws_sqs_queue" "send_on_to_target_server_queue" {
  name                        = "${var.SERVICE}-${var.STAGE}-sendToTargetServer.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0
  visibility_timeout_seconds  = 60
}

