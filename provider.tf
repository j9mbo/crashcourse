provider "google" {
  credentials = "${file("keys.json")}"
  project = "careful-lock-271320"
  region  = "us-central1"
  zone    = "us-central1-a"
}
