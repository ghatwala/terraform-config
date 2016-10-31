variable "env" { default = "staging" }
variable "gce_bastion_image" { default = "eco-emissary-99515/bastion-1475937881" }
variable "gce_gcloud_zone" {}
variable "gce_heroku_org" {}
variable "gce_nat_image" { default = "eco-emissary-99515/nat-1475612719" }
variable "gce_vault_consul_image" { default = "eco-emissary-99515/vault-consul-1473382992" }
variable "gce_worker_image" { default = "eco-emissary-99515/travis-worker-1475934814" }
variable "github_users" {}
variable "index" { default = 1 }
variable "job_board_url" {}

provider "google" {
  project = "travis-staging-1"
}

provider "heroku" {}

data "template_file" "vault_consul_cloud_init" {
  template = "${file("${path.module}/vault-consul-init.tpl")}"
  vars {
    vault_consul_config = "${file("${path.module}/config/vault-consul-env")}"
  }
}

module "vault_consul" {
  source = "../modules/vault_consul"
  cloud_init = "${data.template_file.vault_consul_cloud_init.rendered}"
  env = "${var.env}"
  gce_network = "${module.gce_project_1.gce_network}"
  gce_project = "travis-staging-1"
  gce_subnetwork = "${module.gce_project_1.gce_subnetwork_public}"
  gce_zone = "us-central1-b"
  gce_zone_suffix = "b"
  index = 1
  instance_count = 3
  vault_consul_image = "${var.gce_vault_consul_image}"
}

module "gce_project_1" {
  source = "../modules/gce_project"
  bastion_config = "${file("${path.module}/config/bastion-env")}"
  bastion_image = "${var.gce_bastion_image}"
  env = "${var.env}"
  github_users = "${var.github_users}"
  gcloud_cleanup_account_json = "${file("${path.module}/config/gce-cleanup-staging-1.json")}"
  gcloud_cleanup_job_board_url = "${var.job_board_url}"
  gcloud_cleanup_loop_sleep = "2m"
  gcloud_cleanup_scale = "worker=1:Hobby"
  gcloud_zone = "${var.gce_gcloud_zone}"
  heroku_org = "${var.gce_heroku_org}"
  index = "${var.index}"
  nat_image = "${var.gce_nat_image}"
  project = "travis-staging-1"
  worker_account_json_com = "${file("${path.module}/config/gce-workers-staging.json")}"
  worker_account_json_org = "${file("${path.module}/config/gce-workers-staging.json")}"
  worker_config_com = "${file("${path.module}/config/worker-env-com")}"
  worker_config_org = "${file("${path.module}/config/worker-env-org")}"
  worker_image = "${var.gce_worker_image}"
}
