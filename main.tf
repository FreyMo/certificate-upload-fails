terraform {
    required_providers {
        azurerm = {
            version = "2.48.0"
        }
        azuread = {
            version = "1.3.0"
        }
    }
}

provider "azurerm" {
  features {
    key_vault {
        purge_soft_delete_on_destroy = false
        recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
    location = "westeurope"
}

output "hash" {
    description = "The MD5 file hash to prove that the file content has changed"
    value = filemd5("example.pfx")
}

data "azuread_client_config" "this" {}

resource "random_id" "this" {
  byte_length = 8
}

resource "azurerm_resource_group" "this" {
    name = "rg-${random_id.this.hex}"
    location = local.location
}

resource "azurerm_key_vault" "this" {
    name = "kv-${random_id.this.hex}"
    location = local.location
    resource_group_name = azurerm_resource_group.this.name
    tenant_id = data.azuread_client_config.this.tenant_id
    sku_name = "standard"
    purge_protection_enabled = true
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azuread_client_config.this.tenant_id
  object_id    = data.azuread_client_config.this.object_id

  certificate_permissions = [
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "setissuers",
    "update",
  ]

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "recover",
    "restore",
    "set",
  ]
}

resource "azurerm_key_vault_certificate" "this" {
    name = "my-certificate"
    key_vault_id = azurerm_key_vault.this.id

    depends_on = [
        azurerm_key_vault_access_policy.this
    ]

    certificate_policy {
        issuer_parameters {
          name = "Self"
        }

        key_properties {
            exportable = false
            key_size = 4096
            key_type = "RSA"
            reuse_key = false
        }

        secret_properties {
          content_type = "application/x-pkcs12"
        }
    }

    certificate {
      contents = filebase64("example.pfx")
      password = ""
    }
}