# Configure the AWS Provider
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/Users/csepulveda/.aws/credentials"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.minio_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.minio_vpc.id}"

  tags {
    Name = "main"
  }
}

resource "aws_default_route_table" "r" {
  default_route_table_id = "${aws_vpc.minio_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "default table"
  }
}

resource "aws_vpc" "minio_vpc" {
  cidr_block = "172.16.0.0/16"

  tags {
    Name = "tf-minio"
  }
}

resource "aws_subnet" "minio_subnet" {
  vpc_id            = "${aws_vpc.minio_vpc.id}"
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "tf-minio"
  }
}

variable "nodes" {
  default = 4
}

variable "MINIO_ACCESS_KEY" {
  default = "CZPSXR0VS1JXMVX7PRUE"
}

variable "MINIO_SECRET_KEY" {
  default = "84znI0cO+BC1fOzkzC7of4yfa6lViXlzx6zRQCgw"
}

variable "ebs_size" {
  default = "100"
}

resource "aws_instance" "servers" {
  depends_on = ["aws_spot_instance_request.consul"]
  count      = "${var.nodes}"

  # wait_for_fulfillment = true
  # spot_price           = "0.08"
  ami = "ami-2757f631"

  instance_type   = "c4.large"
  key_name        = "mdstrm"
  security_groups = ["${aws_security_group.allow_all.id}"]

  ebs_block_device = [
    {
      device_name           = "/dev/sdb"
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "${var.ebs_size}"
      delete_on_termination = true
    },
  ]

  connection {
    user        = "ubuntu"
    private_key = "${file("~/.ssh/mdstrm.pem")}"
  }

  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.minio_subnet.id}"

  tags {
    Name = "terraform-minioServer"
  }

  provisioner "file" {
    source      = "minio_servers/minio.json"
    destination = "/tmp/minio.json"
  }

  provisioner "file" {
    source      = "minio_servers/config.json"
    destination = "/tmp/config.json"
  }

  provisioner "file" {
    source      = "minio_servers/server.sh"
    destination = "/tmp/server.sh"
  }

  provisioner "file" {
    source      = "minio_servers/startminio.sh"
    destination = "/tmp/startminio.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.nodes} > /tmp/nodes",
      "echo ${var.MINIO_ACCESS_KEY} > /tmp/MINIO_ACCESS_KEY",
      "echo ${var.MINIO_SECRET_KEY} > /tmp/MINIO_SECRET_KEY",
      "echo ${join(",", aws_spot_instance_request.consul.*.public_ip)} > /tmp/consul.ip",
      "chmod +x /tmp/startminio.sh /tmp/server.sh",
      "sudo bash -x /tmp/server.sh",
    ]
  }
}

resource "aws_spot_instance_request" "consul" {
  spot_price           = "0.08"
  wait_for_fulfillment = true
  ami                  = "ami-2757f631"
  instance_type        = "c4.large"
  key_name             = "mdstrm"
  security_groups      = ["${aws_security_group.allow_all.id}"]

  connection {
    user        = "ubuntu"
    private_key = "${file("~/.ssh/mdstrm.pem")}"
  }

  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.minio_subnet.id}"

  tags {
    Name = "terraform-minioClient"
  }

  provisioner "file" {
    source      = "control_server/mc.sh"
    destination = "/tmp/mc.sh"
  }

  provisioner "file" {
    source      = "control_server/control_server.sh"
    destination = "/tmp/control_server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.nodes} > /tmp/nodes",
      "echo ${var.MINIO_ACCESS_KEY} > /tmp/MINIO_ACCESS_KEY",
      "echo ${var.MINIO_SECRET_KEY} > /tmp/MINIO_SECRET_KEY",
      "chmod +x /tmp/control_server.sh /tmp/mc.sh",
      "sudo bash /tmp/control_server.sh",
    ]
  }
}

output "ip_minio_endpoints" {
  value = "${join(",", aws_instance.servers.*.public_ip)}"
}

output "ip_consulio_redis" {
  value = "${join(",", aws_spot_instance_request.consul.*.public_ip)}"
}

output "MINIO_ACCESS_KEY" {
  value = "${var.MINIO_ACCESS_KEY}"
}

output "MINIO_SECRET_KEY" {
  value = "${var.MINIO_SECRET_KEY}"
}
