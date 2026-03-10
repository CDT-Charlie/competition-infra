# Instance definitions for all of the red team VMs
kali_instances = {
  "red-kali-lucas" = {
    hostname = "red-kali-lucas"
    ip       = "192.168.0.11"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-christian" = {
    hostname = "red-kali-christian"
    ip       = "192.168.0.12"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-swapnil" = {
    hostname = "red-kali-swapnil"
    ip       = "192.168.0.13"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-oliver" = {
    hostname = "red-kali-oliver"
    ip       = "192.168.0.14"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-sonia" = {
    hostname = "red-kali-sonia"
    ip       = "192.168.0.15"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-adam" = {
    hostname = "red-kali-adam"
    ip       = "192.168.0.16"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-gabriel" = {
    hostname = "red-kali-gabriel"
    ip       = "192.168.0.17"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-bryant" = {
    hostname = "red-kali-bryant"
    ip       = "192.168.0.18"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-winter" = {
    hostname = "red-kali-winter"
    ip       = "192.168.0.19"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-caroline" = {
    hostname = "red-kali-caroline"
    ip       = "192.168.0.10"
    flavor   = "large"
    image    = "Kali2025"
  }
}

# Victim instances (3 Windows Server, 3 Ubuntu, 3 Debian) — 9 total
victim_instances = {
  "red-victim-winserv1" = {
    hostname = "red-victim-winserv1"
    ip       = "192.168.0.23"
    flavor   = "large"
    image    = "WindowsServer2022"
  }

  "red-victim-winserv2" = {
    hostname = "red-victim-winserv2"
    ip       = "192.168.0.24"
    flavor   = "large"
    image    = "WindowsServer2022"
  }

  "red-victim-winserv3" = {
    hostname = "red-victim-winserv3"
    ip       = "192.168.0.25"
    flavor   = "large"
    image    = "WindowsServer2022"
  }

  "red-victim-ubuntu1" = {
    hostname = "red-victim-ubuntu1"
    ip       = "192.168.0.26"
    flavor   = "medium"
    image    = "Ubuntu2404Desktop"
  }

  "red-victim-ubuntu2" = {
    hostname = "red-victim-ubuntu2"
    ip       = "192.168.0.27"
    flavor   = "medium"
    image    = "Ubuntu2404Desktop"
  }

  "red-victim-ubuntu3" = {
    hostname = "red-victim-ubuntu3"
    ip       = "192.168.0.28"
    flavor   = "medium"
    image    = "Ubuntu2404Desktop"
  }

  "red-victim-debian1" = {
    hostname = "red-victim-debian1"
    ip       = "192.168.0.29"
    flavor   = "medium"
    image    = "DebianTrixie13"
  }

  "red-victim-debian2" = {
    hostname = "red-victim-debian2"
    ip       = "192.168.0.30"
    flavor   = "medium"
    image    = "DebianTrixie13"
  }

  "red-victim-debian3" = {
    hostname = "red-victim-debian3"
    ip       = "192.168.0.31"
    flavor   = "medium"
    image    = "DebianTrixie13"
  }
}

