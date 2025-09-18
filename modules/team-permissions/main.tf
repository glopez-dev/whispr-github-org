variable "repo_team_permissions" {
  description = "Repository-team permission mappings"
  type = list(object({
    repository = string
    team       = string
    permission = string
  }))
}

variable "teams_map" {
  description = "Teams map from teams module"
  type = map(object({
    id   = string
    name = string
    slug = string
  }))
}

variable "repositories_map" {
  description = "Repositories map from repositories module"
  type = map(object({
    id        = number
    name      = string
    node_id   = string
    full_name = string
  }))
}

# Team repository permissions
resource "github_team_repository" "permissions" {
  for_each = {
    for perm in var.repo_team_permissions : "${perm.repository}-${perm.team}" => perm
  }

  team_id    = var.teams_map[each.value.team].id
  repository = var.repositories_map[each.value.repository].name
  permission = each.value.permission
}

# Outputs
output "team_permissions" {
  description = "Team repository permissions"
  value       = github_team_repository.permissions
}
