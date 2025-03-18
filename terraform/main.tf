# Configure AWS provider
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

# IAM Policies and Roles (unchanged except naming consistency)
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "observer_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "observer_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-ProcessObserverPolicy"
  policy = data.aws_iam_policy_document.observer_policy_doc.json
}

data "aws_iam_policy_document" "observer_data_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "observer_data_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-SendObserverDataPolicy"
  policy = data.aws_iam_policy_document.observer_data_policy_doc.json
}

resource "aws_iam_role" "observer_role" {
  name               = "${var.SERVICE}-${var.STAGE}-ProcessObserverRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role" "observer_data_role" {
  name               = "${var.SERVICE}-${var.STAGE}-SendObserverDataRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role" "fork_ey_observer_data_role" {
  name               = "${var.SERVICE}-${var.STAGE}-ForkEyObserverDataRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "observer_policy_attachment" {
  role       = aws_iam_role.observer_role.name
  policy_arn = aws_iam_policy.observer_policy.arn
}

resource "aws_iam_role_policy_attachment" "observer_data_policy_attachment" {
  role       = aws_iam_role.observer_data_role.name
  policy_arn = aws_iam_policy.observer_data_policy.arn
}






resource "aws_iam_role_policy_attachment" "fork_ey_observer_data_policy_attachment" {
  role       = aws_iam_role.fork_ey_observer_data_role.name
  policy_arn = aws_iam_policy.fork_ey_observer_data_policy.arn
}

data "aws_iam_policy_document" "fork_ey_observer_data_policy_doc" {

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iot:Publish"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem"
    ]
    resources = ["*"]
  }



}

resource "aws_iam_policy" "fork_ey_observer_data_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-ForkEyObserverDataPolicy"
  policy = data.aws_iam_policy_document.fork_ey_observer_data_policy_doc.json
}


