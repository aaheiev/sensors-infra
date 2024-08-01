data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_service_account" "cloud_run_service_sa" {
  project      = var.gcloud_project
  account_id   = "${var.name}-cloud-run"
  display_name = "${var.name}-cloud-run"
  description  = "Service account used by ${var.name} Cloud Run service"
}

resource "google_cloud_run_v2_service" "cloud_run_service" {
  provider = google-beta
  name     = "grafana-${var.gcloud_region}"
  location = var.gcloud_region

  template {
    service_account = google_service_account.cloud_run_service_sa.email
    timeout         = "60s"
    containers {
      name  = "grafana"
      image = "grafana/grafana:11.1.1"
      startup_probe {
        initial_delay_seconds = 100
        timeout_seconds = 10
        period_seconds = 10
        failure_threshold = 3
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
      env {
        name  = "GF_SECURITY_ADMIN_USER"
        value = "sensors"
      }
      env {
        name  = "GF_SERVER_ROOT_URL"
        value = "https://grafana-europe-west4-2xlshubrtq-ez.a.run.app"
      }
      env {
        name = "GF_SECURITY_ADMIN_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.security_admin_password.secret_id
            version = "1"
          }
        }
      }
      env {
        name  = "GF_DATABASE_TYPE"
        value = "postgres"
      }
      env {
        name  = "GF_DATABASE_HOST"
        value = "95.98.208.120:5432"
      }
      env {
        name  = "GF_DATABASE_USER"
        value = "grafana2"
      }
      env {
        name  = "GF_DATABASE_NAME"
        value = "grafana2"
      }
      env {
        name = "GF_DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_password.secret_id
            version = "1"
          }
        }
      }
      ///
      env {
        name  = "GF_AUTH_GOOGLE_ENABLED"
        value = "true"
      }
      env {
        name  = "GF_AUTH_GOOGLE_ALLOW_SIGN_UP"
        value = "true"
      }
      env {
        name  = "GF_AUTH_GOOGLE_SCOPES"
        value = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email"
      }
      env {
        name  = "GF_AUTH_GOOGLE_AUTH_URL"
        value = "https://accounts.google.com/o/oauth2/auth"
      }
      env {
        name  = "GF_AUTH_GOOGLE_TOKEN_URL"
        value = "https://accounts.google.com/o/oauth2/token"
      }

    }
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
  }
}

import {
  id = "europe-west4/grafana-europe-west4"
  to = google_cloud_run_v2_service.cloud_run_service
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = var.gcloud_region
  project     = var.gcloud_project
  service     = google_cloud_run_v2_service.cloud_run_service.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# resource "google_compute_security_policy" "cloud_run_service_security_policy" {
#   name        = "${var.name}-armor-security-policy"
#   description = "Security policy will allow connection only from whitelisted IP ranges"
#
#   # Reject all traffic that hasn't been whitelisted.
#   rule {
#     action   = "deny(403)"
#     priority = "2147483647"
#
#     match {
#       versioned_expr = "SRC_IPS_V1"
#
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#
#     description = "Default rule, higher priority overrides it"
#   }
#
#   # Whitelist traffic from certain ip address
#   rule {
#     action   = "allow"
#     priority = "1000"
#
#     match {
#       versioned_expr = "SRC_IPS_V1"
#
#       config {
#         src_ip_ranges = ["95.98.208.120/32"]
#       }
#     }
#
#     description = "allow traffic from whitelist IP ranges"
#   }
# }

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
  load_balancing_scheme = "EXTERNAL"
  backend {
    group          = google_compute_region_network_endpoint_group.neg.id
    balancing_mode = "UTILIZATION"
  }
  #   security_policy = google_compute_security_policy.cloud_run_service_security_policy.self_link
}
