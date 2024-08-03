data "google_project" "project" {
}

resource "google_secret_manager_secret" "security_admin_password" {
  secret_id = "${var.name}-security-admin-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "security_secret_key" {
  secret_id = "${var.name}-security-secret-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "database_password" {
  secret_id = "${var.name}-database-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "auth_google_client_id" {
  secret_id = "${var.name}-auth-google-client-id"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "auth_google_client_secret" {
  secret_id = "${var.name}-auth-google-client-secret"
  replication {
    auto {}
  }
}

# google_secret_manager_secret_version
data "google_secret_manager_secret_version" "security_admin_password" {
  secret = "${var.name}-security-admin-password"
}

output "secret_version" {
  value = reverse(split("/", data.google_secret_manager_secret_version.security_admin_password.name))[0]
}
