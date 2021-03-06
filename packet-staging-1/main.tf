variable "env" {
  default = "staging"
}

variable "github_users" {}

variable "index" {
  default = 1
}

variable "latest_docker_image_amethyst" {}
variable "latest_docker_image_garnet" {}
variable "latest_docker_image_worker" {}
variable "librato_email" {}
variable "librato_token" {}
variable "packet_auth_token" {}
variable "packet_heroku_org" {}
variable "packet_project_id" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-staging-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "packet" {}
provider "aws" {}
provider "heroku" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/packet-staging-net-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "travis-terraform-state"
  }
}

resource "random_id" "pupcycler_auth" {
  byte_length = 16
}

module "pupcycler" {
  source = "../modules/pupcycler"

  auth_token        = "${random_id.pupcycler_auth.hex}"
  env               = "${var.env}"
  heroku_org        = "${var.packet_heroku_org}"
  index             = "${var.index}"
  packet_project_id = "${var.packet_project_id}"
  packet_auth_token = "${var.packet_auth_token}"
  syslog_address    = "${var.syslog_address_com}"
  version           = "master"
}

data "template_file" "worker_config_com" {
  template = <<EOF
### config/worker-com-local.env
${file("${path.module}/config/worker-com-local.env")}
### config/worker-com.env
${file("${path.module}/config/worker-com.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_DOCKER_INSPECT_INTERVAL=1000ms
export TRAVIS_WORKER_HARD_TIMEOUT=2h
export TRAVIS_WORKER_HEARTBEAT_URL="${replace(module.pupcycler.web_url, "/\\/$/", "")}/heartbeats/___INSTANCE_ID_FULL___"
export TRAVIS_WORKER_HEARTBEAT_URL_AUTH_TOKEN="${random_id.pupcycler_auth.hex}"
export TRAVIS_WORKER_TRAVIS_SITE=com

export TFW_ADMIN_CLEAN_CONTAINERS_MAX_AGE=14400
EOF
}

data "template_file" "worker_config_org" {
  template = <<EOF
### config/worker-org-local.env
${file("${path.module}/config/worker-org-local.env")}
### config/worker-org.env
${file("${path.module}/config/worker-org.env")}
### worker.env
${file("${path.module}/worker.env")}

export TRAVIS_WORKER_DOCKER_INSPECT_INTERVAL=1000ms
export TRAVIS_WORKER_HARD_TIMEOUT=50m
export TRAVIS_WORKER_HEARTBEAT_URL="${replace(module.pupcycler.web_url, "/\\/$/", "")}/heartbeats/___INSTANCE_ID_FULL___"
export TRAVIS_WORKER_HEARTBEAT_URL_AUTH_TOKEN="${random_id.pupcycler_auth.hex}"
export TRAVIS_WORKER_TRAVIS_SITE=org

export TFW_ADMIN_CLEAN_CONTAINERS_MAX_AGE=3600
EOF
}

module "packet_workers_com" {
  source = "../modules/packet_worker"

  bastion_ip                  = "${data.terraform_remote_state.vpc.nat_maint_ip}"
  env                         = "${var.env}"
  facility                    = "${data.terraform_remote_state.vpc.facility}"
  github_users                = "${var.github_users}"
  index                       = "${var.index}"
  librato_email               = "${var.librato_email}"
  librato_token               = "${var.librato_token}"
  nat_ips                     = ["${data.terraform_remote_state.vpc.nat_ips}"]
  nat_public_ips              = ["${data.terraform_remote_state.vpc.nat_public_ips}"]
  project_id                  = "${var.packet_project_id}"
  pupcycler_auth_token        = "${random_id.pupcycler_auth.hex}"
  pupcycler_url               = "${replace(module.pupcycler.web_url, "/\\/$/", "")}"
  server_count                = 1
  site                        = "com"
  syslog_address              = "${var.syslog_address_com}"
  terraform_privkey           = "${data.terraform_remote_state.vpc.terraform_privkey}"
  worker_config               = "${data.template_file.worker_config_com.rendered}"
  worker_docker_image_android = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang  = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go      = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm     = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php     = "${var.latest_docker_image_garnet}"
  worker_docker_image_python  = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby    = "${var.latest_docker_image_garnet}"
  worker_docker_self_image    = "${var.latest_docker_image_worker}"
}

module "packet_workers_org" {
  source = "../modules/packet_worker"

  bastion_ip                  = "${data.terraform_remote_state.vpc.nat_maint_ip}"
  env                         = "${var.env}"
  facility                    = "${data.terraform_remote_state.vpc.facility}"
  github_users                = "${var.github_users}"
  index                       = "${var.index}"
  librato_email               = "${var.librato_email}"
  librato_token               = "${var.librato_token}"
  nat_ips                     = ["${data.terraform_remote_state.vpc.nat_ips}"]
  nat_public_ips              = ["${data.terraform_remote_state.vpc.nat_public_ips}"]
  project_id                  = "${var.packet_project_id}"
  pupcycler_auth_token        = "${random_id.pupcycler_auth.hex}"
  pupcycler_url               = "${replace(module.pupcycler.web_url, "/\\/$/", "")}"
  server_count                = 1
  site                        = "org"
  syslog_address              = "${var.syslog_address_org}"
  terraform_privkey           = "${data.terraform_remote_state.vpc.terraform_privkey}"
  worker_config               = "${data.template_file.worker_config_org.rendered}"
  worker_docker_image_android = "${var.latest_docker_image_amethyst}"
  worker_docker_image_default = "${var.latest_docker_image_garnet}"
  worker_docker_image_erlang  = "${var.latest_docker_image_amethyst}"
  worker_docker_image_go      = "${var.latest_docker_image_garnet}"
  worker_docker_image_haskell = "${var.latest_docker_image_amethyst}"
  worker_docker_image_jvm     = "${var.latest_docker_image_garnet}"
  worker_docker_image_node_js = "${var.latest_docker_image_garnet}"
  worker_docker_image_perl    = "${var.latest_docker_image_amethyst}"
  worker_docker_image_php     = "${var.latest_docker_image_garnet}"
  worker_docker_image_python  = "${var.latest_docker_image_garnet}"
  worker_docker_image_ruby    = "${var.latest_docker_image_garnet}"
  worker_docker_self_image    = "${var.latest_docker_image_worker}"
}
