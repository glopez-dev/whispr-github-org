terraform {

  # Use Terraform Cloud as the backend to store the state file
  backend "remote" {
    organization = "glopez-personnal"

    workspaces {
      name = "whispr-github-org"
    }
  }

  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

}