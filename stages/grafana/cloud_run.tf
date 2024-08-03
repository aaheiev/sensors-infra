locals {
  service_env_vars = {
    "GF_SECURITY_ADMIN_USER"       = "sensors"
    "GF_SERVER_ROOT_URL"           = "https://${local.app_fqdn}"
    "GF_DATABASE_TYPE"             = "postgres"
    "GF_DATABASE_HOST"             = "95.98.208.120:5432"
    "GF_DATABASE_USER"             = "grafana"
    "GF_DATABASE_NAME"             = "grafana"
    "GF_AUTH_GOOGLE_ENABLED"       = "true"
    "GF_AUTH_GOOGLE_ALLOW_SIGN_UP" = "true"
    "GF_AUTH_GOOGLE_SCOPES"        = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email"
    "GF_AUTH_GOOGLE_AUTH_URL"      = "https://accounts.google.com/o/oauth2/auth"
    "GF_AUTH_GOOGLE_TOKEN_URL"     = "https://accounts.google.com/o/oauth2/token"
  }
  service_env_secrets = {
    "GF_SECURITY_ADMIN_PASSWORD" = {
      secret  = data.google_secret_manager_secret.security_admin_password.secret_id
      version = local.security_admin_password_version
    }
    "GF_DATABASE_PASSWORD" = {
      secret  = data.google_secret_manager_secret.database_password.secret_id
      version = local.database_password_version
    }
    "GF_SECURITY_SECRET_KEY" = {
      secret  = data.google_secret_manager_secret.security_secret_key.secret_id
      version = local.security_secret_key_version
    }
    "GF_AUTH_GOOGLE_CLIENT_ID" = {
      secret  = data.google_secret_manager_secret.auth_google_client_id.secret_id
      version = local.auth_google_client_id_version
    }
    "GF_AUTH_GOOGLE_CLIENT_SECRET" = {
      secret  = data.google_secret_manager_secret.auth_google_client_secret.secret_id
      version = local.auth_google_client_secret_version
    }
  }
}

resource "google_cloud_run_v2_service" "cloud_run_service" {
  provider = google-beta
  name     = "grafana-${var.gcloud_region}"
  location = var.gcloud_region

  template {
    service_account = google_service_account.cloud_run_sa.email
    timeout         = "60s"
    containers {
      name  = "grafana"
      image = "grafana/grafana:11.1.1"
      startup_probe {
        initial_delay_seconds = 100
        timeout_seconds       = 10
        period_seconds        = 10
        failure_threshold     = 3
        tcp_socket {
          port = 3000
        }
      }
      liveness_probe {
        http_get {
          path = "/api/health"
          port = 3000
        }
      }
      ports {
        name           = "http1"
        container_port = 3000
      }
      resources {
        cpu_idle = true
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }
      dynamic "env" {
        for_each = local.service_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = local.service_env_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value["secret"]
              version = env.value["version"]
            }
          }
        }
      }
    }
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = var.gcloud_region
  project     = var.gcloud_project
  service     = google_cloud_run_v2_service.cloud_run_service.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "random_id" "group_manager_suffix" {
  byte_length = 4
}

resource "google_compute_region_network_endpoint_group" "neg" {
  project               = var.gcloud_project
  name                  = "${var.name}-${var.gcloud_region}-${random_id.group_manager_suffix.hex}-neg"
  region                = var.gcloud_region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.cloud_run_service.name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = var.name
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group          = google_compute_region_network_endpoint_group.neg.id
    balancing_mode = "UTILIZATION"
  }
}
