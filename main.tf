provider "google" {
  credentials = "${file("keys.json")}"
  project = "careful-lock-271320"
  region  = "us-central1"
  zone    = "us-central1-a"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}
// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
 name         = "flask-vm-${random_id.instance_id.hex}"
 machine_type = "n1-standard-1"
 zone         = "us-central1-c"
 boot_disk {
   initialize_params {
     image = "ubuntu-1804-lts"
   }
 }
// Make sure flask is installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask; sudo apt install curl; curl -4 icanhazip.com | tee ip.txt"
network_interface {
   network = "my-network-11"
   access_config {
     // Include this section to give the VM an external ip address
   }
 }
 metadata = {
   ssh-keys = "nevermind:${file("~/id_rsa.pub")}"
 }
}
