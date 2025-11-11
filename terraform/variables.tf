variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-terraform-demo-working"
}

variable "location" {
  description = "Azure region for the Resource Group"
  type        = string
  default     = "East US"
}