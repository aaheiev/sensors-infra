resource "google_service_account" "cloud_run_sa" {
  project      = var.gcloud_project
  account_id   = "${var.name}-cloud-run"
  display_name = "${var.name}-cloud-run service account"
  description  = "Service account used by ${var.name} Cloud Run service"
}
