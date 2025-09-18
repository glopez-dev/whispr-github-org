variable "repositories" {
  description = "Repositories map"
  type = map(object({
    id        = number
    name      = string
    node_id   = string
    full_name = string
  }))
}

variable "ruleset_config" {
  description = "Repository ruleset configuration"
  type = map(object({
    target      = optional(string, "branch")
    enforcement = optional(string, "active")
    conditions = optional(object({
      ref_name = optional(object({
        include = optional(list(string), ["~DEFAULT_BRANCH"])
        exclude = optional(list(string), [])
      }), {})
    }), {})
    rules = optional(object({
      branch_name_pattern = optional(object({
        pattern = string
        name    = optional(string, "Branch naming convention")
        negate  = optional(bool, false)
      }), null)
      commit_message_pattern = optional(object({
        pattern = string
        name    = optional(string, "Commit message format")
        negate  = optional(bool, false)
      }), null)
      pull_request = optional(object({
        dismiss_stale_reviews_on_push     = optional(bool, true)
        require_code_owner_reviews        = optional(bool, true)
        require_last_push_approval        = optional(bool, false)
        required_approving_review_count   = optional(number, 1)
        required_review_thread_resolution = optional(bool, true)
      }), null)
      required_status_checks = optional(object({
        strict_required_status_checks_policy = optional(bool, true)
        required_status_checks = optional(list(object({
          context = string
        })), [])
      }), null)
    }), {})
  }))
  default = {}
}

# Repository rulesets
resource "github_repository_ruleset" "rulesets" {
  for_each = {
    for pair in setproduct(keys(var.repositories), keys(var.ruleset_config)) :
    "${pair[0]}-${pair[1]}" => {
      repository = pair[0]
      ruleset    = pair[1]
      config     = var.ruleset_config[pair[1]]
    }
  }
  
  name        = each.value.ruleset
  repository  = var.repositories[each.value.repository].name
  target      = each.value.config.target
  enforcement = each.value.config.enforcement
  
  # Conditions
  conditions {
    ref_name {
      include = each.value.config.conditions.ref_name.include
      exclude = each.value.config.conditions.ref_name.exclude
    }
  }
  
  # Rules
  rules {
    # Branch name pattern
    dynamic "branch_name_pattern" {
      for_each = each.value.config.rules.branch_name_pattern != null ? [each.value.config.rules.branch_name_pattern] : []
      content {
        pattern = branch_name_pattern.value.pattern
        name    = branch_name_pattern.value.name
        negate  = branch_name_pattern.value.negate
      }
    }
    
    # Commit message pattern
    dynamic "commit_message_pattern" {
      for_each = each.value.config.rules.commit_message_pattern != null ? [each.value.config.rules.commit_message_pattern] : []
      content {
        pattern = commit_message_pattern.value.pattern
        name    = commit_message_pattern.value.name
        negate  = commit_message_pattern.value.negate
      }
    }
    
    # Pull request rules
    dynamic "pull_request" {
      for_each = each.value.config.rules.pull_request != null ? [each.value.config.rules.pull_request] : []
      content {
        dismiss_stale_reviews_on_push     = pull_request.value.dismiss_stale_reviews_on_push
        require_code_owner_reviews        = pull_request.value.require_code_owner_reviews
        require_last_push_approval        = pull_request.value.require_last_push_approval
        required_approving_review_count   = pull_request.value.required_approving_review_count
        required_review_thread_resolution = pull_request.value.required_review_thread_resolution
      }
    }
    
    # Required status checks
    dynamic "required_status_checks" {
      for_each = each.value.config.rules.required_status_checks != null ? [each.value.config.rules.required_status_checks] : []
      content {
        strict_required_status_checks_policy = required_status_checks.value.strict_required_status_checks_policy
        
        dynamic "required_status_checks" {
          for_each = required_status_checks.value.required_status_checks
          content {
            context = required_status_checks.value.context
          }
        }
      }
    }
  }
}

# Outputs
output "repository_rulesets" {
  description = "Repository rulesets"
  value       = github_repository_ruleset.rulesets
}