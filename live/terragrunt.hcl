remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "bijlmerdreef733-infra"
    prefix = format("%s", get_path_from_repo_root())
  }
}
