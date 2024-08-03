data "google_project" "project" {
}

data "google_secret_manager_secret" "security_admin_password" {
  secret_id = "${var.name}-security-admin-password"
}

data "google_secret_manager_secret_version" "security_admin_password" {
  secret = "${var.name}-security-admin-password"
}

data "google_secret_manager_secret" "security_secret_key" {
  secret_id = "${var.name}-security-secret-key"
}

data "google_secret_manager_secret_version" "security_secret_key" {
  secret = "${var.name}-security-secret-key"
}

data "google_secret_manager_secret" "database_password" {
  secret_id = "${var.name}-database-password"
}

data "google_secret_manager_secret_version" "database_password" {
  secret = "${var.name}-database-password"
}

data "google_secret_manager_secret" "auth_google_client_id" {
  secret_id = "${var.name}-auth-google-client-id"
}

data "google_secret_manager_secret_version" "auth_google_client_id" {
  secret = "${var.name}-auth-google-client-id"
}

data "google_secret_manager_secret" "auth_google_client_secret" {
  secret_id = "${var.name}-auth-google-client-secret"
}

data "google_secret_manager_secret_version" "auth_google_client_secret" {
  secret = "${var.name}-auth-google-client-secret"
}

locals {
  security_admin_password_version   = reverse(split("/", data.google_secret_manager_secret_version.security_admin_password.name))[0]
  security_secret_key_version       = reverse(split("/", data.google_secret_manager_secret_version.security_secret_key.name))[0]
  database_password_version         = reverse(split("/", data.google_secret_manager_secret_version.database_password.name))[0]
  auth_google_client_id_version     = reverse(split("/", data.google_secret_manager_secret_version.auth_google_client_id.name))[0]
  auth_google_client_secret_version = reverse(split("/", data.google_secret_manager_secret_version.auth_google_client_secret.name))[0]
}

resource "google_secret_manager_secret_iam_member" "security_admin_password_access" {
  for_each = toset([
    data.google_secret_manager_secret.security_admin_password.id,
    data.google_secret_manager_secret.security_secret_key.id,
    data.google_secret_manager_secret.database_password.id,
    data.google_secret_manager_secret.auth_google_client_id.id,
    data.google_secret_manager_secret.auth_google_client_secret.id
  ])
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
