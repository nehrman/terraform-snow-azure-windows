##############################################################################
# Variables Files
# 
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "env" {
  description = "Environnement"
  default     = "dev"
}

variable "resource_group" {
  description = "The name of your Azure Resource Group."
  default     = "Azure-Vault-Neh-Demo"
}

variable "demo_prefix" {
  description = "This prefix will be included in the name of some resources."
  default     = "avsdemo"
}

variable "hostname" {
  description = "VM hostname. Used for local hostname, DNS, and storage-related names."
  default     = "neh-test"
}

variable "location" {
  description = "The region where the virtual network is created."
  default     = "francecentral"
}

variable "virtual_network_name" {
  description = "The name for your virtual network."
  default     = "vnet-neh"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  type = list
  default     = ["10.0.10.0/24"]
}

variable "storage_account_tier" {
  description = "Defines the storage tier. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "storage_disk_size" {
  description = "Defines the OS disk size. minimum is 70"
  default     = "100"
}

variable "storage_replication_type" {
  description = "Defines the replication type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_D4_v3"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "16.04-LTS"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name"
  default     = "nicolas"
}

variable "admin_password" {
  description = "Administrator password"
  default     = "P4sswOrd"
}

variable "servers" {
  description = "Number of servers to deploy"
  default     = 3
}

variable "availabilityset" {
  description = "Use an Availibilty Set or not"
  default     = true
}

