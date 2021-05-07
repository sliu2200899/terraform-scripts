
resource "digitalocean_droplet" "web1" {
  image = "ubuntu-16-04-x64"
  name = "web1"
  region = "nyc1"
  size = "s-1vcpu-1gb"
  private_networking = true
  user_data = file("config/webuserdata.sh")
  ssh_keys = [
    var.ssh_fingerprint
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
}