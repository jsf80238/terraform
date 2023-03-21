# Create a VPC
resource "google_compute_network" "vpc_network" {
  name                    = "jasons-custom-network"
  project                 = "verdant-bond-262820"  # This was missing from Google's documentation
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Create a subnet
resource "google_compute_subnetwork" "default" {
  name          = "jasons-custom-subnet"
  project       = "verdant-bond-262820"  # This was missing from Google's documentation
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.id
}

# Create a single Compute Engine instance
resource "google_compute_instance" "default" {
  name         = "jasons-vm"
  project      = "verdant-bond-262820"  # This was missing from Google's documentation
  # machine_type = "f1-micro"
  machine_type = "e2-micro"  # f1-micro might have worked, but according to Google's documentation the e2-micro is guaranteed to be free
  zone         = "us-west1-a"  # Low-CO2 according to Google
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Install Flask
  metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python3-pip rsync; pip install flask"

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}

# Create a firewall & rule enabling SSH traffic from the internet to my VM
resource "google_compute_firewall" "ssh" {
  name          = "allow-ssh"
  project       = "verdant-bond-262820"  # This was missing from Google's documentation
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# Create a firewall & rule enabling HTTP traffic from the internet to my VM
resource "google_compute_firewall" "flask" {
  name    = "flask-app-firewall"
  project = "verdant-bond-262820"  # This was missing from Google's documentation
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# And as a convenience, output the IP address my VM will answer to via HTTP
// A variable for extracting the external IP address of the VM
output "Web-server-URL" {
 value = join("",["http://",google_compute_instance.default.network_interface.0.access_config.0.nat_ip,":5000"])
}
