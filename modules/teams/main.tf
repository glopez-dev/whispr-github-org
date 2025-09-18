variable "teams_config" {
  description = "Teams configuration"
  type = map(object({
    name        = string
    description = string
    privacy     = optional(string, "closed")
    members     = optional(list(string), [])
    maintainers = optional(list(string), [])
    parent_team = optional(string, "")
  }))
}

# Create teams
resource "github_team" "teams" {
  for_each = var.teams_config
  
  name           = each.value.name
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = each.value.parent_team != "" ? github_team.teams[each.value.parent_team].id : null
}

# Team memberships
resource "github_team_membership" "memberships" {
  for_each = {
    for pair in flatten([
      for team_key, team_config in var.teams_config : [
        for member in team_config.members : {
          team_key = team_key
          username = member
          role     = contains(team_config.maintainers, member) ? "maintainer" : "member"
        }
      ]
    ]) : "${pair.team_key}-${pair.username}" => pair
  }
  
  team_id  = github_team.teams[each.value.team_key].id
  username = each.value.username
  role     = each.value.role
}

# Outputs
output "teams" {
  description = "Created teams"
  value       = github_team.teams
}

output "teams_map" {
  description = "Teams mapped by name"
  value = {
    for team_key, team in github_team.teams : team_key => {
      id   = team.id
      name = team.name
      slug = team.slug
    }
  }
}