output "instance_master_public_ip" {
  description = "Public address IP of master"
  value       = aws_instance.ec2_instance_master.public_ip
}

output "ecr_repository_uri" {
  description = "ECR repo URI"
  value       = aws_ecr_repository.uiservice.repository_url
}
