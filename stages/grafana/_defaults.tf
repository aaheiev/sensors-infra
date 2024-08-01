variable "terragrunt_path" {
  type    = string
  default = ""
}

locals {
  default_labels = {
    "managed-by" = "terraform"
    "stage"      = "shared"
  }
}
