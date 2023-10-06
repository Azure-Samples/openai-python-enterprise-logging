terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.66.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.7.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  name     = "openai${random_string.unique.result}"
  location = var.location

  tags = {
    "managed_by" = "terraform"
    "repo"       = "openai-python-enterprise-logging"
  }
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name}-${local.location}"
  location = local.location
  tags     = local.tags
}

