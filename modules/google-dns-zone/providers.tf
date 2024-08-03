provider "google" {
  project = var.gcloud_project
  region  = var.gcloud_region
}

provider "google-beta" {
  project = var.gcloud_project
  region  = var.gcloud_region
}
