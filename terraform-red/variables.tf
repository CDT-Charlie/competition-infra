variable "kali_instances" {
  description = "Kali VMs on the charlie-red-team network"
  type = map(object({
    hostname         = string
    ip               = string
    flavor           = string
    image           = string
    root_volume_size = optional(number, 60)
  }))
}

variable "victim_instances" {
  description = "Victim VMs (Windows/Linux) on the charlie-red-team network"
  type = map(object({
    hostname         = string
    ip               = string
    flavor           = string
    image            = string
    root_volume_size = optional(number, 60)
  }))
  default = {}
}

