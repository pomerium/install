resource "random_password" "pomerium" {
  length  = 16
  special = false
}

resource "google_sql_database_instance" "pomerium" {
  name             = local.db_instance_name
  region           = var.gcp_region
  database_version = "POSTGRES_16"
  settings {
    edition = "ENTERPRISE"
    tier    = var.db_tier
  }
}

locals {
  db_instance_name = "pomerium"

  sql_proxy_sidecar = {
    name  = "cloud-sql-proxy"
    image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest"
    args = [
      "--structured-logs",
      "--port=5432",
      "${var.gcp_project}:${var.gcp_region}:${local.db_instance_name}"
    ]
    security_context = {
      run_as_non_root = true
    }
    resources = {
      requests = {
        cpu    = "1"
        memory = "2Gi"
      }
    }
  }

}
resource "google_sql_database" "core" {
  name     = "pomerium-core"
  instance = google_sql_database_instance.pomerium.name
}

resource "google_sql_database" "console" {
  name     = "pomerium-enterprise"
  instance = google_sql_database_instance.pomerium.name
}

resource "google_sql_user" "pomerium" {
  name     = "pomerium"
  password = random_password.pomerium.result
  instance = google_sql_database_instance.pomerium.name
}

resource "google_service_account" "pomerium" {
  account_id   = "pomerium"
  display_name = "Pomerium Service Account"
}

resource "google_service_account_iam_binding" "pomerium" {
  service_account_id = google_service_account.pomerium.email
  role               = "roles/cloudsql.client"
  members            = ["serviceAccount:${google_service_account.pomerium.email}"]
}
