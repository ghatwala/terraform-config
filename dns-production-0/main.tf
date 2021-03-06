variable "env" {
  default = "production"
}

variable "index" {
  default = 0
}

variable "heroku_org" {}

variable "macstadium_production_nat_addrs" {
  type = "list"
}

variable "travisci_net_external_zone_id" {
  default = "Z2RI61YP4UWSIO"
}

variable "whereami_scale" {
  type    = "list"
  default = ["web=1:Standard-1X"]
}

variable "whereami_version" {
  default = "master"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/dns-production-0.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {}
provider "heroku" {}

data "dns_a_record_set" "aws_production_2_nat_com" {
  host = "workers-nat-com-shared-2.aws-us-east-1.travisci.net"
}

data "dns_a_record_set" "aws_production_2_nat_org" {
  host = "workers-nat-org-shared-2.aws-us-east-1.travisci.net"
}

data "dns_a_record_set" "gce_production_1_nat" {
  host = "nat-production-1.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_2_nat" {
  host = "nat-production-2.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_3_nat" {
  host = "nat-production-3.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_4_nat" {
  host = "nat-production-4.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "gce_production_5_nat" {
  host = "nat-production-5.gce-us-central1.travisci.net"
}

data "dns_a_record_set" "packet_production_1_nat" {
  host = "nat-production-1.packet-ewr1.travisci.net"
}

resource "aws_route53_record" "aws_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.aws-us-east-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
  ]
}

resource "aws_route53_record" "gce_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.gce-us-central1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.gce_production_1_nat.addrs}",
    "${data.dns_a_record_set.gce_production_2_nat.addrs}",
    "${data.dns_a_record_set.gce_production_3_nat.addrs}",
    "${data.dns_a_record_set.gce_production_4_nat.addrs}",
    "${data.dns_a_record_set.gce_production_5_nat.addrs}",
  ]
}

resource "aws_route53_record" "linux_containers_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.linux-containers.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}

resource "aws_route53_record" "macstadium_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300

  records = ["${var.macstadium_production_nat_addrs}"]
}

resource "aws_route53_record" "packet_nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.packet-ewr1.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}

resource "aws_route53_record" "nat" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "nat.travisci.net"
  type    = "A"
  ttl     = 300

  records = [
    "${data.dns_a_record_set.aws_production_2_nat_com.addrs}",
    "${data.dns_a_record_set.aws_production_2_nat_org.addrs}",
    "${data.dns_a_record_set.gce_production_1_nat.addrs}",
    "${data.dns_a_record_set.gce_production_2_nat.addrs}",
    "${data.dns_a_record_set.gce_production_3_nat.addrs}",
    "${data.dns_a_record_set.gce_production_4_nat.addrs}",
    "${data.dns_a_record_set.gce_production_5_nat.addrs}",
    "${var.macstadium_production_nat_addrs}",
    "${data.dns_a_record_set.packet_production_1_nat.addrs}",
  ]
}

resource "heroku_app" "whereami" {
  name   = "whereami-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    MANAGED_VIA = "github.com/travis-ci/terraform-config"

    WHEREAMI_INFRA_EC2_IPS = "${
      join(",", data.dns_a_record_set.aws_production_2_nat_com.addrs)
    },${
      join(",", data.dns_a_record_set.aws_production_2_nat_org.addrs)
    }"

    WHEREAMI_INFRA_GCE_IPS = "${
      join(",", data.dns_a_record_set.gce_production_1_nat.addrs)
    },${
      join(",", data.dns_a_record_set.gce_production_2_nat.addrs)
    },${
      join(",", data.dns_a_record_set.gce_production_3_nat.addrs)
    },${
      join(",", data.dns_a_record_set.gce_production_4_nat.addrs)
    },${
      join(",", data.dns_a_record_set.gce_production_5_nat.addrs)
    }"

    WHEREAMI_INFRA_MACSTADIUM_IPS = "${
      join(",", var.macstadium_production_nat_addrs)
    }"

    WHEREAMI_INFRA_PACKET_IPS = "${
      join(",", data.dns_a_record_set.packet_production_1_nat.addrs)
    }"
  }
}

resource "null_resource" "whereami" {
  triggers {
    config_signature = "${sha256(join(",", values(heroku_app.whereami.config_vars.0)))}"
    heroku_id        = "${heroku_app.whereami.id}"
    scale            = "${join(",", var.whereami_scale)}"
    version          = "${var.whereami_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/heroku-wait-deploy-scale \
  --repo=travis-ci/whereami \
  --app=${heroku_app.whereami.id} \
  --ps-scale=${join(",", var.whereami_scale)} \
  --deploy-version=${var.whereami_version}
EOF
  }
}
