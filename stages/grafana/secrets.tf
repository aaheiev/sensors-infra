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

resource "google_secret_manager_secret_iam_member" "security_admin_password_access" {
  secret_id = google_secret_manager_secret.security_admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "security_secret_key_access" {
  secret_id = google_secret_manager_secret.security_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "database_password_access" {
  secret_id = google_secret_manager_secret.database_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_sa.email}"
}
