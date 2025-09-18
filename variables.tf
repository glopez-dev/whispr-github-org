variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "organization_name" {
  description = "GitHub organization name"
  type        = string
}

variable "admin_email" {
  description = "Organization admin email"
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

variable "default_branch" {
  description = "Default branch name"
  type        = string
  default     = "main"
}

variable "security_settings" {
  description = "Security settings"
  type = object({
    require_two_factor          = optional(bool, true)
    advanced_security_enabled   = optional(bool, true)
    secret_scanning_enabled     = optional(bool, true)
    push_protection_enabled     = optional(bool, true)
    dependency_graph_enabled    = optional(bool, true)
    dependabot_alerts_enabled   = optional(bool, true)
    dependabot_security_updates = optional(bool, true)
  })
  default = {}
}

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

variable "repositories_config" {
  description = "Repositories configuration"
  type = map(map(object({
    description        = string
    topics             = optional(list(string), [])
    visibility         = optional(string, "private")
    has_issues         = optional(bool, true)
    has_projects       = optional(bool, false)
    has_wiki           = optional(bool, false)
    template           = optional(string, "")
    teams              = optional(map(string), {})
    auto_init          = optional(bool, false)
    gitignore_template = optional(string, "")
    license_template   = optional(string, "")
  })))
}

variable "repository_templates" {
  description = "Repository templates"
  type = map(object({
    owner      = string
    repository = string
  }))
  default = {
    microservice = {
      owner      = "your-org"
      repository = "microservice-template"
    }
    frontend = {
      owner      = "your-org"
      repository = "frontend-template"
    }
  }
}

variable "standard_labels" {
  description = "Standard labels for repositories"
  type = list(object({
    name        = string
    color       = string
    description = string
  }))
  default = [
    {
      name        = "bug"
      color       = "d73a4a"
      description = "Something isn't working"
    },
    {
      name        = "enhancement"
      color       = "a2eeef"
      description = "New feature or request"
    },
    {
      name        = "documentation"
      color       = "0075ca"
      description = "Improvements or additions to documentation"
    },
    {
      name        = "high-priority"
      color       = "ff0000"
      description = "High priority issue"
    },
    {
      name        = "needs-review"
      color       = "fbca04"
      description = "Needs code review"
    },
    {
      name        = "wontfix"
      color       = "ffffff"
      description = "This will not be worked on"
    },
    {
      name        = "duplicate"
      color       = "cfd3d7"
      description = "This issue or pull request already exists"
    },
    {
      name        = "good first issue"
      color       = "7057ff"
      description = "Good for newcomers"
    },
    {
      name        = "help wanted"
      color       = "008672"
      description = "Extra attention is needed"
    }
  ]
}

variable "organization_variables" {
  description = "Organization-wide GitHub Actions variables"
  type = map(object({
    value                 = string
    visibility            = string
    selected_repositories = optional(list(string), [])
  }))
  default = {}
}

variable "organization_secrets" {
  description = "Organization-wide GitHub Actions secrets"
  type = map(object({
    value                 = string
    visibility            = string
    selected_repositories = optional(list(string), [])
  }))
  default   = {}
  sensitive = true
}

variable "branch_protection_config" {
  description = "Branch protection rules"
  type = map(object({
    pattern             = string
    enforce_admins      = optional(bool, false)
    allows_deletions    = optional(bool, false)
    allows_force_pushes = optional(bool, false)
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
  default = {}
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
