# SSH key name
output "key_name" {
  description = "SSH key name"
  value       = aws_key_pair.ssh_key.key_name
}
