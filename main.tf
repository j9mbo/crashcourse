terraform {

  required_version = ">= 0.12"
}

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

module "lb" {
  source                = "./modules/http-load-balancer"
  name                  = var.name
  project               = var.project
  url_map               = google_compute_url_map.default.self_link
  dns_managed_zone_name = var.dns_managed_zone_name
  custom_domain_names   = [var.custom_domain_name]
  create_dns_entries    = var.create_dns_entry
  dns_record_ttl        = var.dns_record_ttl
  enable_http           = var.enable_http
  enable_ssl            = var.enable_ssl
  ssl_certificates      = google_compute_ssl_certificate.default.self_link

  custom_labels = var.custom_labels
}

resource "google_compute_global_address" "default" {
  project      = var.project
  name         = "${var.name}-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "https" {
  provider   = google-beta
  project    = var.project
  count      = var.enable_ssl ? 1 : 0
  name       = "${var.name}-https-rule"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  depends_on = [google_compute_global_address.default]

  labels = var.custom_labels
}

resource "google_compute_ssl_certificate" "default" {
  name_prefix = "my-certificate"
  description = "a description"
  private_key = file("privkey.pem")
   certificate = file("cert.pem")

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "default" {
  project = var.project
  count   = var.enable_ssl ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = google_compute_ssl_certificate.default.*.id
}


resource "google_compute_http_health_check" "default" {
  name = "tcp-health-check-3"

  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 5
  port = 80
}

resource "google_compute_url_map" "default" {
  name            = "${var.name}-global-pcf"
  default_service = google_compute_backend_service.api.self_link
}

resource "google_compute_backend_service" "api" {
  project = var.project

  name        = "${var.name}-api"
  description = "API Backend for ${var.name}"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  backend {
    group = google_compute_instance_group_manager.api.instance_group
  }

  health_checks = [google_compute_http_health_check.default.self_link]

  depends_on = [
      google_compute_instance_group_manager.api
  ]
}

resource "google_compute_autoscaler" "default" {
  provider = google-beta

  name   = "${var.name}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.api.self_link

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "api" {
  provider  = google-beta
  project   = var.project
  name      = "${var.name}-instance-group"
  zone      = var.zone

  update_policy {
    type = "PROACTIVE"
    minimal_action = "RESTART"
    max_surge_fixed = 0
    max_unavailable_fixed = 1
    min_ready_sec = 0
  }

  version {
    instance_template = google_compute_instance_template.api.self_link
    name              = "primary"
  }

  lifecycle {
    create_before_destroy = true
  }

  named_port {
    name = "http"
    port = 80
  }

  base_instance_name = "autoscaler-sample"

  auto_healing_policies {
    health_check      = google_compute_http_health_check.default.self_link
    initial_delay_sec = 60
  }

}

resource "google_compute_instance_template" "api" {
  project      = var.project
  name         = "${var.name}-instance-2"
  machine_type = "f1-micro"

  tags = ["private-app"]

  disk {
    source_image = "ubuntu-1604-lts"
  }

  metadata = {
   ssh-keys = "vital:${file("~/.ssh/id_rsa.pub")}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
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
    ports    = ["80","22","443"]
  }

}

resource "google_dns_managed_zone" "prod" {
  name        = "example-zone"
  dns_name    = "crashnovi.xyz."
  description = "Example DNS zone"
}

resource "google_dns_record_set" "www" {
  name = "www.${google_dns_managed_zone.prod.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "default" {
  name = google_dns_managed_zone.prod.dns_name
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = [google_compute_global_address.default.address]
}



  

