output "vpc_id" {
  value = data.aws_vpc.existing_vpc_1.id
}

output "subnet_a" {
  value = data.aws_subnet.selected_a.id
}

output "subnet_b" {
  value = data.aws_subnet.selected_b.id
}

output "send_data_sg_id" {
  value = aws_security_group.send_data_sg.id
}

output "send_on_to_target_server_arn" {
  value       = aws_sqs_queue.send_on_to_target_server_queue.arn
  description = "ARN of the SendData SQS queue"
}

output "send_on_to_target_server_queue_url" {
  value       = aws_sqs_queue.send_on_to_target_server_queue.id
  description = "URL of the SendData SQS queue"
}

output "observer_zip_table_arn" {
  value       = aws_dynamodb_table.observer_zip_table.arn
  description = "ARN of the ObserverDataTable DynamoDB table"
}


output "observer_zip_table_name" {
  value       = aws_dynamodb_table.observer_zip_table.name
  description = "Name of the ObserverDataTable DynamoDB table"
}

output "devkey_cache_name" {
  value       = aws_dynamodb_table.devkey_cache_table.name
  description = "Name of the Devkey Cache DynamoDB table"
}

output "observer_role_arn" {
  value       = aws_iam_role.observer_role.arn
  description = "ARN of the ProcessObserverRole IAM role"
}

output "observer_data_role_arn" {
  value       = aws_iam_role.observer_data_role.arn
  description = "ARN of the SendObserverDataRole IAM role"
}
