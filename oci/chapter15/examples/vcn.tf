variable "compartment_ocid" {}
variable "vcn_name" {}
variable "vcn_dns_label" {}
variable "vcn_cidr_block" {}

resource "oci_core_virtual_network" "vcn1" {
  cidr_block     = var.vcn_cidr_block
  dns_label      = var.vcn_dns_label
  compartment_id = var.compartment_ocid
  display_name   = var.vcn_name
}

output "vcn1_ocid" {
  value = ["${oci_core_virtual_network.vcn1.id}"]
}