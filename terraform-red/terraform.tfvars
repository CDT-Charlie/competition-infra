# Instance definitions for all of the red team VMs
kali_instances = {
  "red-kali-1" = {
    hostname = "red-kali-1"
    ip       = "192.168.0.11"
    flavor   = "large"
    image    = "Kali2025"
  }

  "red-kali-2" = {
    hostname = "red-kali-2"
    ip       = "192.168.0.12"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-3" = {
    hostname = "red-kali-3"
    ip       = "192.168.0.13"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-4" = {
    hostname = "red-kali-4"
    ip       = "192.168.0.14"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-5" = {
    hostname = "red-kali-5"
    ip       = "192.168.0.15"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-6" = {
    hostname = "red-kali-6"
    ip       = "192.168.0.16"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-7" = {
    hostname = "red-kali-7"
    ip       = "192.168.0.17"
    flavor   = "large"
    image    = "Kali2025"
  }

      "red-kali-8" = {
    hostname = "red-kali-8"
    ip       = "192.168.0.18"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-9" = {
    hostname = "red-kali-9"
    ip       = "192.168.0.19"
    flavor   = "large"
    image    = "Kali2025"
  }

    "red-kali-10" = {
    hostname = "red-kali-10"
    ip       = "192.168.0.10"
    flavor   = "large"
    image    = "Kali2025"
  }
}

# Victim instances (Windows Server, Windows 10, Linux) — ~10 total
victim_instances = {
  "red-victim-win10-1" = {
    hostname = "red-victim-win10-1"
    ip       = "192.168.0.20"
    flavor   = "medium"
    image    = "Windows10"
  }

  "red-victim-win10-2" = {
    hostname = "red-victim-win10-2"
    ip       = "192.168.0.21"
    flavor   = "medium"
    image    = "Windows10"
  }

  "red-victim-win10-3" = {
    hostname = "red-victim-win10-3"
    ip       = "192.168.0.22"
    flavor   = "medium"
    image    = "Windows10"
  }

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
    image    = "Ubuntu2204Desktop"
  }

  "red-victim-ubuntu2" = {
    hostname = "red-victim-ubuntu2"
    ip       = "192.168.0.27"
    flavor   = "medium"
    image    = "Ubuntu2204Desktop"
  }

  "red-victim-ubuntu3" = {
    hostname = "red-victim-ubuntu-2404"
    ip       = "192.168.0.28"
    flavor   = "medium"
    image    = "Ubuntu2404Desktop"
  }

  "red-victim-debian" = {
    hostname = "red-victim-debian"
    ip       = "192.168.0.29"
    flavor   = "medium"
    image    = "DebianBookworm12"
  }
}

