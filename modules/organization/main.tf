variable "organization_name" {
  description = "GitHub organization name"
  type        = string
}

variable "admin_email" {
  description = "Admin email for the organization"
  type        = string
}

variable "company_name" {
  description = "Company name"
  type        = string
  default     = ""
}

variable "blog_url" {
  description = "Organization blog URL"
  type        = string
  default     = ""
}

variable "contact_email" {
  description = "Contact email"
  type        = string
  default     = ""
}

variable "location" {
  description = "Organization location"
  type        = string
  default     = ""
}

variable "display_name" {
  description = "Organization display name"
  type        = string
  default     = ""
}

variable "security_settings" {
  description = "Security settings configuration"
  type = object({
    require_two_factor              = optional(bool, true)
    advanced_security_enabled       = optional(bool, true)
    secret_scanning_enabled         = optional(bool, true)
    push_protection_enabled         = optional(bool, true)
    dependency_graph_enabled        = optional(bool, true)
    dependabot_alerts_enabled       = optional(bool, true)
    dependabot_security_updates     = optional(bool, true)
  })
  default = {}
}

variable "organization_variables" {
  description = "Organization-wide GitHub Actions variables"
  type = map(object({
    value      = string
    visibility = string
    selected_repositories = optional(list(string), [])
  }))
  default = {}
}

variable "organization_secrets" {
  description = "Organization-wide GitHub Actions secrets"
  type = map(object({
    value                 = string
    visibility           = string
    selected_repositories = optional(list(string), [])
  }))
  default = {}
  sensitive = true
}

# Organization settings
resource "github_organization_settings" "main" {
  billing_email = var.admin_email
  company       = var.company_name
  blog          = var.blog_url
  email         = var.contact_email
  location      = var.location
  name          = var.display_name != "" ? var.display_name : var.organization_name
  
  # Repository creation permissions
  members_can_create_repositories               = false
  members_can_create_public_repositories        = false
  members_can_create_private_repositories       = false
  members_allowed_repository_creation_type      = "none"
  
  # Pages permissions
  members_can_create_pages                     = false
  members_can_create_public_pages              = false
  members_can_create_private_pages             = false
  
  # Fork permissions
  members_can_fork_private_repositories        = false
  
  # Default permissions
  default_repository_permission                = "read"
  
  # Security features
  dependency_graph_enabled_for_new_repositories = var.security_settings.dependency_graph_enabled
  dependabot_alerts_enabled_for_new_repositories = var.security_settings.dependabot_alerts_enabled
  dependabot_security_updates_enabled_for_new_repositories = var.security_settings.dependabot_security_updates
  
  # Commit signature requirement
  web_commit_signoff_required = true
}

# Advanced security and analysis
resource "github_organization_security_and_analysis" "main" {
  secret_scanning {
    status = var.security_settings.secret_scanning_enabled ? "enabled" : "disabled"
  }
  
  secret_scanning_push_protection {
    status = var.security_settings.push_protection_enabled ? "enabled" : "disabled"
  }
  
  dependency_graph {
    status = var.security_settings.dependency_graph_enabled ? "enabled" : "disabled"
  }
  
  dependabot_alerts {
    status = var.security_settings.dependabot_alerts_enabled ? "enabled" : "disabled"
  }
  
  dependabot_security_updates {
    status = var.security_settings.dependabot_security_updates ? "enabled" : "disabled"
  }
  
  advanced_security {
    status = var.security_settings.advanced_security_enabled ? "enabled" : "disabled"
  }
}

# Organization variables
resource "github_actions_organization_variable" "variables" {
  for_each = var.organization_variables
  
  variable_name           = each.key
  value                  = each.value.value
  visibility             = each.value.visibility
  selected_repository_ids = each.value.visibility == "selected" ? each.value.selected_repositories : null
}

# Organization secrets
resource "github_actions_organization_secret" "secrets" {
  for_each = var.organization_secrets
  
  secret_name             = each.key
  visibility              = each.value.visibility
  selected_repository_ids = each.value.visibility == "selected" ? each.value.selected_repositories : null
  plaintext_value         = each.value.value
}

# Outputs
output "organization_id" {
  description = "Organization ID"
  value       = github_organization_settings.main.id
}