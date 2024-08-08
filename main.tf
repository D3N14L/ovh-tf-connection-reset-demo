terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "0.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

#############
# Variables #
#############

variable "customer_name" {
  type = string
}

variable "bucket_count" {
  default = 25
}

###################
# Provider config #
###################

provider "ovh" {}

provider "aws" {
  region     = "de"
  access_key = try(ovh_cloud_project_user_s3_credential.s3_admin_cred.access_key_id, "bogus")
  secret_key = try(ovh_cloud_project_user_s3_credential.s3_admin_cred.secret_access_key, "bogus")

  #OVH implementation has no STS service
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  # the OVH regions are unknown to AWS hence skipping is needed.
  skip_region_validation = true
  endpoints {
    s3 = "s3.de.io.cloud.ovh.net"
  }
}

###############
# OVH Project #
###############

data "ovh_order_cart" "project_cart" {
  ovh_subsidiary = "DE"
}

data "ovh_order_cart_product_plan" "cloud_project" {
  cart_id        = data.ovh_order_cart.project_cart.id
  price_capacity = "renew"
  product        = "cloud"
  plan_code      = "project.2018"
}

resource "ovh_cloud_project" "cloud_project" {
  ovh_subsidiary = data.ovh_order_cart.project_cart.ovh_subsidiary
  description    = "connection-reset-test"

  plan {
    duration     = data.ovh_order_cart_product_plan.cloud_project.selected_price.0.duration
    plan_code    = data.ovh_order_cart_product_plan.cloud_project.plan_code
    pricing_mode = data.ovh_order_cart_product_plan.cloud_project.selected_price.0.pricing_mode
  }

  lifecycle {
    ignore_changes = [
      plan,
      ovh_subsidiary
    ]
  }
}

###############
# OVH S3 user #
###############

resource "ovh_cloud_project_user" "openstack" {
  service_name = ovh_cloud_project.cloud_project.project_id
  description  = "GaaS IaaC OpenStack user"
  role_name    = "administrator"
}

resource "ovh_cloud_project_user_s3_credential" "s3_admin_cred" {
  service_name = ovh_cloud_project.cloud_project.project_id
  user_id      = ovh_cloud_project_user.openstack.id
}
