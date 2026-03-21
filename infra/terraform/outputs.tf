output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "auth_db_endpoint" {
  description = "Endpoint do RDS do auth-service"
  value       = aws_db_instance.auth.address
}

output "auth_db_port" {
  description = "Porta do RDS do auth-service"
  value       = aws_db_instance.auth.port
}

output "auth_db_name" {
  description = "Nome do banco do auth-service"
  value       = aws_db_instance.auth.db_name
}

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "flag_db_endpoint" {
  description = "Endpoint do RDS do flag-service"
  value       = aws_db_instance.flag.address
}

output "flag_db_port" {
  description = "Porta do RDS do flag-service"
  value       = aws_db_instance.flag.port
}

output "flag_db_name" {
  description = "Nome do banco do flag-service"
  value       = aws_db_instance.flag.db_name
}

output "targeting_db_endpoint" {
  description = "Endpoint do RDS do targeting-service"
  value       = aws_db_instance.targeting.address
}

output "targeting_db_port" {
  description = "Porta do RDS do targeting-service"
  value       = aws_db_instance.targeting.port
}

output "targeting_db_name" {
  description = "Nome do banco do targeting-service"
  value       = aws_db_instance.targeting.db_name
}

output "evaluation_sqs_url" {
  description = "URL da fila SQS do evaluation-service"
  value       = aws_sqs_queue.evaluation_events.url
}

output "analytics_dynamodb_table" {
  description = "Nome da tabela DynamoDB do analytics-service"
  value       = aws_dynamodb_table.analytics.name
}