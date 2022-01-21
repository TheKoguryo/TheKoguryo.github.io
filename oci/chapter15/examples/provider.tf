variable "region" {}

provider "oci" {
  region           = "${var.region}"
}