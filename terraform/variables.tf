variable "instances" {
  description = "VMs keyed by name. Specify network (admin, red, blue1, blue2), ip, flavor, image."
  type = map(object({
    network          = string
    ip               = string
    flavor           = string
    image            = string
    root_volume_size = optional(number, 60)
  }))
}
