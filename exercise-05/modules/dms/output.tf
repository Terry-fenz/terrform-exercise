# DMS 覆寫個體的 的 id
output "replication_instance_public_ips" {
  description = "Replication instance public ips"
  value       = module.database_migration_service.replication_instance_public_ips
}
