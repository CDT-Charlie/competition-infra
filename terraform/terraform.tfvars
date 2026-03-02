# Admin network: 10.100.0.0/24
# Red network:   10.100.1.0/24
# Blue1 network: 10.100.2.0/24
# Blue2 network: 10.100.3.0/24
instances = {
  "blue1-win10-test" = {
    network = "blue1"
    ip      = "10.100.2.4"
    flavor  = "medium"
    image   = "Windows10"
  }

  "blue1-winserv-test" = {
    network = "blue1"
    ip      = "10.100.2.5"
    flavor  = "large"
    image   = "WindowsServer2022"
  }

  "blue1-debian-bookworm-test" = {
    network = "blue1"
    ip      = "10.100.2.6"
    flavor  = "medium"
    image   = "DebianBookworm12"
  }

  "blue1-debian-bookworm-server-test" = {
    network = "blue1"
    ip      = "10.100.2.7"
    flavor  = "medium"
    image   = "debian-bookworm-server"
  }

  "blue1-ubuntu-2204-desktop-test" = {
    network = "blue1"
    ip      = "10.100.2.8"
    flavor  = "medium"
    image   = "Ubuntu2204Desktop"
  }

    "blue1-kali-2025-test" = {
    network = "blue1"
    ip      = "10.100.2.9"
    flavor  = "medium"
    image   = "Kali2025"
  }

}
