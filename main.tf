terraform {

  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR GCP CONNECTION
# ------------------------------------------------------------------------------

provider "google" {
  credentials = file("keys.json")
  version = "~> 2.7.0"
  region  = var.region
  project = var.project
}

provider "google-beta" {
  credentials = file("keys.json")
  version = "~> 2.7.0"
  region  = var.region
  project = var.project
}

# ------------------------------------------------------------------------------
# CREATE THE LOAD BALANCER
# ------------------------------------------------------------------------------

module "lb" {
  source                = "./modules/http-load-balancer"
  name                  = var.name
  project               = var.project
  url_map               = google_compute_url_map.urlmap.self_link
  dns_managed_zone_name = var.dns_managed_zone_name
  custom_domain_names   = [var.custom_domain_name]
  create_dns_entries    = var.create_dns_entry
  dns_record_ttl        = var.dns_record_ttl
  enable_http           = var.enable_http
  enable_ssl            = var.enable_ssl
  ssl_certificates      = google_compute_ssl_certificate.certificate.*.self_link

  custom_labels = var.custom_labels
}

# ------------------------------------------------------------------------------
# CREATE THE URL MAP TO MAP PATHS TO BACKENDS
# ------------------------------------------------------------------------------

resource "google_compute_url_map" "urlmap" {
  project = var.project

  name        = "${var.name}-url-map"
  description = "URL map for ${var.name}"

  default_service = google_compute_backend_bucket.static.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "all"
  }

  path_matcher {
    name            = "all"
    default_service = google_compute_backend_bucket.static.self_link

    path_rule {
      paths   = ["/api", "/api/*"]
      service = google_compute_backend_service.api.self_link
    }
  }
}

# ------------------------------------------------------------------------------
# CREATE THE BACKEND SERVICE CONFIGURATION FOR THE INSTANCE GROUP
# ------------------------------------------------------------------------------

resource "google_compute_backend_service" "api" {
  project = var.project

  name        = "${var.name}-api"
  description = "API Backend for ${var.name}"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  health_checks = [google_compute_http_health_check.default.self_link]

  depends_on = [google_compute_instance_group_manager.default]
}

# ------------------------------------------------------------------------------
# CONFIGURE HEALTH CHECK FOR THE API BACKEND
# ------------------------------------------------------------------------------

resource "google_compute_http_health_check" "default" {
  name         = "authentication-health-check-2"
  request_path = "/health_check"

  timeout_sec        = 1
  check_interval_sec = 1
}

# ------------------------------------------------------------------------------
# CREATE THE STORAGE BUCKET FOR THE STATIC CONTENT
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "static" {
  project = var.project

  name          = "${var.name}-bucket"
  location      = var.static_content_bucket_location
  storage_class = "MULTI_REGIONAL"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # For the example, we want to clean up all resources. In production, you should set this to false to prevent
  # accidental loss of data
  force_destroy = true

  labels = var.custom_labels
}

# ------------------------------------------------------------------------------
# CREATE THE BACKEND FOR THE STORAGE BUCKET
# ------------------------------------------------------------------------------

resource "google_compute_backend_bucket" "static" {
  project = var.project

  name        = "${var.name}-backend-bucket"
  bucket_name = google_storage_bucket.static.name
}

# ------------------------------------------------------------------------------
# UPLOAD SAMPLE CONTENT WITH PUBLIC READ ACCESS
# ------------------------------------------------------------------------------

resource "google_storage_default_object_acl" "website_acl" {
  bucket      = google_storage_bucket.static.name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "index" {
  name    = "index.html"
  content = "Hello, World!"
  bucket  = google_storage_bucket.static.name

  # We have to depend on the ACL because otherwise the ACL could get created after the object
  depends_on = [google_storage_default_object_acl.website_acl]
}

resource "google_storage_bucket_object" "not_found" {
  name    = "404.html"
  content = "Uh oh"
  bucket  = google_storage_bucket.static.name

  # We have to depend on the ACL because otherwise the ACL could get created after the object
  depends_on = [google_storage_default_object_acl.website_acl]
}

# ------------------------------------------------------------------------------
# IF SSL IS ENABLED, CREATE A SELF-SIGNED CERTIFICATE
# ------------------------------------------------------------------------------

resource "tls_self_signed_cert" "cert" {
  # Only create if SSL is enabled
  count = var.enable_ssl ? 1 : 0

  key_algorithm   = "RSA"
  private_key_pem = join("", tls_private_key.private_key.*.private_key_pem)

  subject {
    common_name  = var.custom_domain_name
    organization = "Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "private_key" {
  count       = var.enable_ssl ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P256"
}

# ------------------------------------------------------------------------------
# CREATE A CORRESPONDING GOOGLE CERTIFICATE THAT WE CAN ATTACH TO THE LOAD BALANCER
# ------------------------------------------------------------------------------

resource "google_compute_ssl_certificate" "certificate" {
  project = var.project

  count = var.enable_ssl ? 1 : 0

  name_prefix = var.name
  description = "SSL Certificate"
  private_key = join("", tls_private_key.private_key.*.private_key_pem)
  certificate = join("", tls_self_signed_cert.cert.*.cert_pem)

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# CREATE THE INSTANCE GROUP WITH A SINGLE INSTANCE AND THE BACKEND SERVICE CONFIGURATION
#
# We use the instance group only to highlight the ability to specify multiple types
# of backends for the load balancer
# ------------------------------------------------------------------------------

resource "google_compute_autoscaler" "default" {
  provider = google-beta

  name   = "${var.name}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.default.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.9
    }
  }
}

resource "google_compute_instance_group_manager" "default" {
  provider  = google-beta
  project   = var.project
  name      = "${var.name}-instance-group"
  zone      = var.zone

  version {
    instance_template = google_compute_instance_template.api.self_link
    name              = "primary"
  }

  target_pools = ["${google_compute_target_pool.template.self_link}"]

  lifecycle {
    create_before_destroy = true
  }

  base_instance_name = "autoscaler-sample"
  named_port {
    name = "http"
    port = 5000
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.default.self_link
    initial_delay_sec = 60
  }
}

resource "google_compute_instance_template" "api" {
  project      = var.project
  name         = "${var.name}-instance1"
  machine_type = "f1-micro"

  tags = ["private-app"]

  disk {
    source_image = "ubuntu-1804-lts"
  }

  metadata = {
    metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask; sudo apt install curl"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  network_interface {
    subnetwork = "default"

    access_config {
    }
  }
}

# ------------------------------------------------------------------------------
# CREATE A FIREWALL TO ALLOW ACCESS FROM THE LB TO THE INSTANCE
# ------------------------------------------------------------------------------

resource "google_compute_target_pool" "template" {
  name = "template"
}

resource "google_compute_firewall" "firewall" {
  project = var.project
  name    = "${var.name}-fw"
  network = "default"

  # Allow load balancer access to the API instances
  # https://cloud.google.com/load-balancing/docs/https/#firewall_rules
  source_ranges = ["0.0.0.0/0"]

  target_tags = ["private-app"]
  source_tags = ["private-app"]

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
}

