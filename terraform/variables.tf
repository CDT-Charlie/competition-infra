variable "blue1_instances" {
    description = "Boxes on blue1 network"
    type = map(object({
      ip = string
      flavor = string
      image = string
    }))
}

# variable "blue2_instances" {
#     description = "Boxes on blue2 network"
#     type = map(object({
#       ip = string
#       flavor = string
#       image = string
#     }))
# }