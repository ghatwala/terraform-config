variable "env" {
  default = "production"
}

variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}

variable "gce_worker_image" {
  default = "https://www.googleapis.com/compute/v1/projects/eco-emissary-99515/global/images/tfw-1516675156-0b5be43"
}

variable "github_users" {}
variable "job_board_url" {}

variable "project" {
  default = "travis-ci-prod-4"
}

variable "syslog_address_com" {}
variable "syslog_address_org" {}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "worker_instance_count_com" {}
variable "worker_instance_count_org" {}

variable "worker_instance_count_com_free" {
  default = "0"
}

variable "worker_zones" {
  default = ["a", "b", "f"]
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-4.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "google" {
  project = "${var.project}"
  region  = "us-central1"
}

provider "aws" {}
provider "heroku" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/gce-production-net-4.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

module "gce_worker_group" {
  source = "../modules/gce_worker_group"

  env                           = "${var.env}"
  gcloud_cleanup_job_board_url  = "${var.job_board_url}"
  gcloud_zone                   = "${var.gce_gcloud_zone}"
  github_users                  = "${var.github_users}"
  heroku_org                    = "${var.gce_heroku_org}"
  index                         = "4"
  project                       = "${var.project}"
  region                        = "us-central1"
  syslog_address_com            = "${var.syslog_address_com}"
  syslog_address_org            = "${var.syslog_address_org}"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  worker_image                  = "${var.gce_worker_image}"
  worker_subnetwork             = "${data.terraform_remote_state.vpc.gce_subnetwork_workers}"

  worker_zones = "${var.worker_zones}"

  worker_instance_count_com      = "${var.worker_instance_count_com}"
  worker_instance_count_com_free = "${var.worker_instance_count_com_free}"
  worker_instance_count_org      = "${var.worker_instance_count_org}"

  worker_config_com = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF

  worker_config_com_free = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce-free
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-com
export TRAVIS_WORKER_HARD_TIMEOUT=120m
export TRAVIS_WORKER_TRAVIS_SITE=com
EOF

  worker_config_org = <<EOF
### worker.env
${file("${path.module}/worker.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}

export TRAVIS_WORKER_QUEUE_NAME=builds.gce
export TRAVIS_WORKER_GCE_SUBNETWORK=jobs-org
export TRAVIS_WORKER_TRAVIS_SITE=org
EOF
}

output "workers_service_account_email" {
  value = "${module.gce_worker_group.workers_service_account_email}"
}
