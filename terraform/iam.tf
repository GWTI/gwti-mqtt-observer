# Assume role policy for Lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Policy for Lambda processing Kinesis, SQS, DynamoDB
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

  statement {
    effect    = "Allow"
    actions   = ["iot:Publish"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListStreams"
    ]
    resources = [aws_kinesis_stream.data_stream.arn] # Reference to Kinesis stream
  }
}

resource "aws_iam_policy" "observer_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-ProcessObserverPolicy"
  policy = data.aws_iam_policy_document.observer_policy_doc.json
}

# Policy for SQS consumer Lambda
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
      "ec2:DescribeVpcs",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "observer_data_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-SendObserverDataPolicy"
  policy = data.aws_iam_policy_document.observer_data_policy_doc.json
}

# Policy for fork_ey_observer_data_role (unchanged)
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



# IAM Role for IoT to write to Kinesis
data "aws_iam_policy_document" "iot_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iot_kinesis_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = [aws_kinesis_stream.data_stream.arn]
  }
}

resource "aws_iam_policy" "iot_kinesis_policy" {
  name   = "${var.SERVICE}-${var.STAGE}-IotKinesisPolicy"
  policy = data.aws_iam_policy_document.iot_kinesis_policy_doc.json
}

resource "aws_iam_role" "iot_kinesis_role" {
  name               = "${var.SERVICE}-${var.STAGE}-IotKinesisRole"
  assume_role_policy = data.aws_iam_policy_document.iot_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "iot_kinesis_policy_attachment" {
  role       = aws_iam_role.iot_kinesis_role.name
  policy_arn = aws_iam_policy.iot_kinesis_policy.arn
}

# Lambda Roles
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

# Policy Attachments
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
