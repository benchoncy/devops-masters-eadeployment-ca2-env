locals {
  include_previous_revision = can(local.suffixs.blue) || random_pet.revision_suffix.id != try(local.suffixs.green, random_pet.revision_suffix.id)
  blue_suffix = try(random_pet.revision_suffix.id == local.suffixs.green ? local.suffixs.blue : local.suffixs.green, "")
  suffixs = var.init ? {} : {for tw in data.azurerm_container_app.current[0].ingress[0].traffic_weight[*] : tw.label => tw.revision_suffix if tw.label != ""}
  traffic = merge({
    "${random_pet.revision_suffix.id}" = {
      label = "green"
      percentage = var.traffic.green.percentage
    }
  }, local.include_previous_revision ? {
    "${local.blue_suffix}" = {
      label = "blue"
      percentage = var.traffic.blue.percentage
    }
  } : {})
}

data "azurerm_subscription" "primary" {}

data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

data "azurerm_container_app" "current" {
  count = var.init ? 0 : 1
  name                = "${var.app_name}-app"
  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "bpcalc" {
  name                = "${var.app_name}-identity-${terraform.workspace}"
  location            = data.azurerm_resource_group.target.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "pull" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.bpcalc.principal_id
}

resource "random_pet" "revision_suffix" {
  keepers = {
    # Generate a new name each time we switch revision level items
    registry = var.image_registry
    image = var.image_name
    tag = var.image_tag
    max_replicas = var.max_replicas
    cpu = var.cpu
    memory = var.memory
    external_ingress = var.external_ingress
    env = jsonencode(var.env_vars)
    probe = jsonencode(var.liveness_probe)
  }
}

resource "azurerm_container_app" "app" {
  name                         = "${var.app_name}-app"
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Multiple"

  template {
    max_replicas = var.max_replicas
    revision_suffix = random_pet.revision_suffix.id

    container {
      name   = var.app_name
      image  = "${var.image_registry}/${var.image_name}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory
      dynamic env {
        for_each = var.env_vars
        content {
          name = env.key
          value = env.value
        }
      }
      liveness_probe {
        initial_delay = var.liveness_probe.initial_delay
        interval_seconds = var.liveness_probe.interval_seconds
        failure_count_threshold = var.liveness_probe.failure_count_threshold
        path = var.liveness_probe.path
        port = var.liveness_probe.port
        transport = var.liveness_probe.transport
      }
    }
  }

  ingress {
    target_port = var.port
    external_enabled = var.external_ingress
    dynamic traffic_weight {
      for_each = local.traffic
      content {
        label = traffic_weight.value.label
        revision_suffix = traffic_weight.key
        percentage = traffic_weight.value.percentage
      }
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.bpcalc.id]
  }

  registry {
    server = var.image_registry
    identity = azurerm_user_assigned_identity.bpcalc.id
  }
}

resource "null_resource" "deactivate_old_revisions" {
  depends_on = [
    azurerm_container_app.app
  ]
  triggers = {
    blue = local.blue_suffix
  }
  provisioner "local-exec" {
    command = "if ${!var.init}; then az containerapp revision deactivate --revision ${var.app_name}-app--${try(local.suffixs.blue, "")} -g ${var.resource_group_name}; fi"
    on_failure = continue
  }
}

output "latest_revision_suffix" {
  value = random_pet.revision_suffix.id
}

output "app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}

output "app_name" {
  value = azurerm_container_app.app.name
}