output "organization_settings" {
  description = "Organization settings"
  value = {
    id   = module.organization_settings.organization_id
    name = var.organization_name
  }
}

output "teams" {
  description = "Created teams"
  value       = module.teams.teams_map
}

output "repositories" {
  description = "Created repositories"
  value       = module.repositories.repositories_map
}

output "branch_protections" {
  description = "Branch protection rules"
  value       = module.branch_protection.branch_protections
}