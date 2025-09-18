variable "repositories" {
  description = "Repositories map"
  type = map(object({
    id        = number
    name      = string
    node_id   = string
    full_name = string
  }))
}

variable "branch_protection_config" {
  description = "Branch protection configuration"
  type = map(object({
    pattern                         = string
    enforce_admins                 = optional(bool, false)
    allows_deletions               = optional(bool, false)
    allows_force_pushes           = optional(bool, false)
    required_status_checks = optional(object({
      strict   = optional(bool, true)
      contexts = optional(list(string), [])
    }), null)
    required_pull_request_reviews = optional(object({
      dismiss_stale_reviews           = optional(bool, true)
      require_code_owner_reviews      = optional(bool, true)
      required_approving_review_count = optional(number, 1)
      restrict_pushes                 = optional(bool, true)
    }), null)
    push_restrictions = optional(list(string), [])
  }))
}

variable "teams_map" {
  description = "Teams map for push restrictions"
  type = map(object({
    id   = string
    name = string
    slug = string
  }))
}

# Branch protection rules
resource "github_branch_protection" "protection" {
  for_each = {
    for pair in setproduct(keys(var.repositories), keys(var.branch_protection_config)) :
    "${pair[0]}-${pair[1]}" => {
      repository = pair[0]
      rule       = pair[1]
      config     = var.branch_protection_config[pair[1]]
    }
  }
  
  repository_id = var.repositories[each.value.repository].node_id
  pattern       = each.value.config.pattern
  
  # Admin enforcement
  enforce_admins = each.value.config.enforce_admins
  
  # Deletion and force push settings
  allows_deletions    = each.value.config.allows_deletions
  allows_force_pushes = each.value.config.allows_force_pushes
  
  # Required status checks
  dynamic "required_status_checks" {
    for_each = each.value.config.required_status_checks != null ? [each.value.config.required_status_checks] : []
    content {
      strict   = required_status_checks.value.strict
      contexts = required_status_checks.value.contexts
    }
  }
  
  # Required pull request reviews
  dynamic "required_pull_request_reviews" {
    for_each = each.value.config.required_pull_request_reviews != null ? [each.value.config.required_pull_request_reviews] : []
    content {
      dismiss_stale_reviews           = required_pull_request_reviews.value.dismiss_stale_reviews
      require_code_owner_reviews      = required_pull_request_reviews.value.require_code_owner_reviews
      required_approving_review_count = required_pull_request_reviews.value.required_approving_review_count
      restrict_pushes                 = required_pull_request_reviews.value.restrict_pushes
    }
  }
  
  # Push restrictions
  dynamic "restrict_pushes" {
    for_each = length(each.value.config.push_restrictions) > 0 ? [1] : []
    content {
      push_allowances = [
        for team_name in each.value.config.push_restrictions :
        var.teams_map[team_name].id
      ]
    }
  }
}

# Outputs
output "branch_protections" {
  description = "Branch protection rules"
  value       = github_branch_protection.protection
}
