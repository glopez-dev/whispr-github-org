


provider "github" {
  token = var.github_token
  owner = var.organization_name
}

# Local values for computed configurations
locals {
  # Flatten repositories for easier iteration
  all_repositories = merge(
    var.repositories_config.microservices,
    var.repositories_config.infrastructure,
    lookup(var.repositories_config, "frontend", {}),
    lookup(var.repositories_config, "mobile", {}),
    lookup(var.repositories_config, "docs", {})
  )

  # Create repository-team mapping
  repo_team_permissions = flatten([
    for repo_name, repo_config in local.all_repositories : [
      for team_name, permission in repo_config.teams : {
        repository = repo_name
        team       = team_name
        permission = permission
      }
    ]
  ])
}

# Organization settings module
module "organization_settings" {
  source = "./modules/organization"

  organization_name      = var.organization_name
  admin_email            = var.admin_email
  company_name           = var.company_name
  blog_url               = var.blog_url
  contact_email          = var.contact_email
  location               = var.location
  display_name           = var.display_name
  security_settings      = var.security_settings
  organization_variables = var.organization_variables
  organization_secrets   = var.organization_secrets
}

# Teams module
module "teams" {
  source = "./modules/teams"

  teams_config = var.teams_config

  depends_on = [module.organization_settings]
}

# Repositories module
module "repositories" {
  source = "./modules/repositories"

  repositories_config  = local.all_repositories
  organization_name    = var.organization_name
  default_branch       = var.default_branch
  repository_templates = var.repository_templates
  standard_labels      = var.standard_labels

  depends_on = [module.teams]
}

# Team permissions module
module "team_permissions" {
  source = "./modules/team-permissions"

  repo_team_permissions = local.repo_team_permissions
  teams_map             = module.teams.teams_map
  repositories_map      = module.repositories.repositories_map

  depends_on = [module.teams, module.repositories]
}

# Branch protection module
module "branch_protection" {
  source = "./modules/branch-protection"

  repositories             = module.repositories.repositories_map
  branch_protection_config = var.branch_protection_config
  teams_map                = module.teams.teams_map

  depends_on = [module.repositories, module.team_permissions]
}

# Repository rulesets module
module "repository_rulesets" {
  source = "./modules/repository-rulesets"

  repositories   = module.repositories.repositories_map
  ruleset_config = var.ruleset_config

  depends_on = [module.repositories]
}