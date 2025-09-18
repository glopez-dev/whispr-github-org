variable "repositories_config" {
  description = "Repositories configuration"
  type = map(object({
    description    = string
    topics        = optional(list(string), [])
    visibility    = optional(string, "private")
    has_issues    = optional(bool, true)
    has_projects  = optional(bool, false)
    has_wiki      = optional(bool, false)
    template      = optional(string, "")
    teams         = optional(map(string), {})
    auto_init     = optional(bool, false)
    gitignore_template = optional(string, "")
    license_template   = optional(string, "")
  }))
}

variable "organization_name" {
  description = "GitHub organization name"
  type        = string
}

variable "default_branch" {
  description = "Default branch name"
  type        = string
  default     = "main"
}

variable "repository_templates" {
  description = "Repository templates configuration"
  type = map(object({
    owner      = string
    repository = string
  }))
  default = {}
}

variable "standard_labels" {
  description = "Standard labels for all repositories"
  type = list(object({
    name        = string
    color       = string
    description = string
  }))
  default = []
}

# Create repositories
resource "github_repository" "repositories" {
  for_each = var.repositories_config
  
  name         = each.key
  description  = each.value.description
  visibility   = each.value.visibility
  
  # Repository features
  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki
  
  # Repository settings
  delete_branch_on_merge = true
  vulnerability_alerts   = true
  
  # Merge settings
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = true
  
  # Template configuration
  dynamic "template" {
    for_each = each.value.template != "" ? [1] : []
    content {
      owner      = var.repository_templates[each.value.template].owner
      repository = var.repository_templates[each.value.template].repository
    }
  }
  
  # Topics
  topics = each.value.topics
  
  # Auto init
  auto_init          = each.value.auto_init
  gitignore_template = each.value.gitignore_template != "" ? each.value.gitignore_template : null
  license_template   = each.value.license_template != "" ? each.value.license_template : null
}

# Repository labels
resource "github_issue_label" "standard_labels" {
  for_each = {
    for pair in setproduct(keys(var.repositories_config), var.standard_labels) :
    "${pair[0]}-${pair[1].name}" => {
      repository = pair[0]
      label      = pair[1]
    }
  }
  
  repository  = github_repository.repositories[each.value.repository].name
  name        = each.value.label.name
  color       = each.value.label.color
  description = each.value.label.description
}

# Repository files (templates, workflows, etc.)
resource "github_repository_file" "gitignore" {
  for_each = { for k, v in var.repositories_config : k => v if v.gitignore_template != "" }

  repository          = github_repository.repositories[each.key].name
  branch              = var.default_branch
  file                = ".gitignore"
  content = templatefile("${path.module}/templates/gitignore/${each.value.gitignore_template != "" ? each.value.gitignore_template : "default"}.gitignore", {
    repository_name = each.key
  })
  commit_message      = "chore: add .gitignore template"
  commit_author       = "Terraform Bot"
  commit_email        = "terraform@${var.organization_name}.com"
  overwrite_on_create = true
}

# PR Template
resource "github_repository_file" "pr_template" {
  for_each = var.repositories_config
  
  repository          = github_repository.repositories[each.key].name
  branch              = var.default_branch
  file                = ".github/pull_request_template.md"
  content = templatefile("${path.module}/templates/pull_request_template.md", {
    repository_name = each.key
  })
  commit_message      = "chore: add PR template"
  commit_author       = "Terraform Bot"
  commit_email        = "terraform@${var.organization_name}.com"
  overwrite_on_create = true
}

# Issue templates
resource "github_repository_file" "bug_template" {
  for_each = var.repositories_config
  
  repository          = github_repository.repositories[each.key].name
  branch              = var.default_branch
  file                = ".github/ISSUE_TEMPLATE/bug_report.yml"
  content = templatefile("${path.module}/templates/issue_templates/bug_report.yml", {
    repository_name = each.key
  })
  commit_message      = "chore: add bug report template"
  commit_author       = "Terraform Bot"
  commit_email        = "terraform@${var.organization_name}.com"
  overwrite_on_create = true
}

resource "github_repository_file" "feature_template" {
  for_each = var.repositories_config
  
  repository          = github_repository.repositories[each.key].name
  branch              = var.default_branch
  file                = ".github/ISSUE_TEMPLATE/feature_request.yml"
  content = templatefile("${path.module}/templates/issue_templates/feature_request.yml", {
    repository_name = each.key
  })
  commit_message      = "chore: add feature request template"
  commit_author       = "Terraform Bot"
  commit_email        = "terraform@${var.organization_name}.com"
  overwrite_on_create = true
}

# GitHub Actions workflows
resource "github_repository_file" "ci_workflow" {
  for_each = {
    for repo_name, repo_config in var.repositories_config : 
    repo_name => repo_config
    if contains(repo_config.topics, "microservice")
  }
  
  repository          = github_repository.repositories[each.key].name
  branch              = var.default_branch
  file                = ".github/workflows/ci.yml"
  content = templatefile("${path.module}/templates/workflows/ci.yml", {
    repository_name = each.key
    organization    = var.organization_name
  })
  commit_message      = "chore: add CI workflow"
  commit_author       = "Terraform Bot"
  commit_email        = "terraform@${var.organization_name}.com"
  overwrite_on_create = true
}

# Outputs
output "repositories" {
  description = "Created repositories"
  value       = github_repository.repositories
}

output "repositories_map" {
  description = "Repositories mapped by name"
  value = {
    for repo_name, repo in github_repository.repositories : repo_name => {
      id       = repo.repo_id
      name     = repo.name
      node_id  = repo.node_id
      full_name = repo.full_name
    }
  }
}