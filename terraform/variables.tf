variable "blue1_instances" {
  description = "Boxes on blue1 network"
  type = map(object({
    ip           = string
    flavor       = string
    image        = string
    # Size (GB) of the *root* Cinder volume created from `image` (boot_index = 0).
    # Default keeps tfvars minimal while ensuring the OS disk is a volume (not ephemeral).
    root_volume_size = optional(number, 60)
  }))
}

variable "blue2_instances" {
  description = "Boxes on blue2 network"
  type = map(object({
    ip           = string
    flavor       = string
    image        = string
    root_volume_size = optional(number, 60)
  }))
  default = {}
}

# variable "blue2_instances" {
#     description = "Boxes on blue2 network"
#     type = map(object({
#       ip = string
#       flavor = string
#       image = string
#     }))
# }