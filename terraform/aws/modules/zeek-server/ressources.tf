
data "aws_ami" "zeek_server_packer" {
  count       = (var.zeek_server.zeek_server == "1") && (var.general.use_prebuilt_images_with_packer == "1") ? 1 : 0
  most_recent = true
  owners      = ["self"] 

  filter {
    name   = "name"
    values = [var.zeek_server.zeek_image]
  }
}

data "aws_ami" "zeek_server" {
  count       = (var.zeek_server.zeek_server == "1") && (var.general.use_prebuilt_images_with_packer == "0") ? 1 : 0
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
      name   = "name"
      values = ["*ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

resource "aws_instance" "zeek_sensor" {
  count       = var.zeek_server.zeek_server == "1" ? 1 : 0
  ami           = var.general.use_prebuilt_images_with_packer == "1" ? data.aws_ami.zeek_server_packer[0].id : data.aws_ami.zeek_server[0].id
  instance_type = "m5.2xlarge"
  key_name      = var.general.key_name
  subnet_id = var.ec2_subnet_id
  vpc_security_group_ids = [var.vpc_security_group_ids]
  private_ip = "10.0.1.50"
  associate_public_ip_address = true

  tags = {
    Name = "ar-zeek-${var.general.key_name}-${var.general.attack_range_name}"
  }

  provisioner "remote-exec" {
    inline = ["echo booted"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file(var.aws.private_key_path)
    }
  }

  provisioner "local-exec" {
    working_dir = "../../packer/ansible"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.aws.private_key_path} -i '${self.public_ip},' zeek.yml -e 'ansible_python_interpreter=/usr/bin/python3 ${join(" ", [for key, value in var.splunk_server : "${key}=\"${value}\""])} ${join(" ", [for key, value in var.general : "${key}=\"${value}\""])}'"
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.aws.private_key_path} -i '${self.public_ip},' zeek_server_post.yml -e 'ansible_python_interpreter=/usr/bin/python3 ${join(" ", [for key, value in var.splunk_server : "${key}=\"${value}\""])}'"
  }
}

resource "aws_eip" "zeek_ip" {
  count       = (var.zeek_server.zeek_server == "1") && (var.aws.use_elastic_ips == "1") ? 1 : 0
  instance    = aws_instance.zeek_sensor[0].id
}

resource "aws_ec2_traffic_mirror_target" "zeek_target" {
  count = var.zeek_server.zeek_server == "1" ? 1 : 0
  description          = "VPC Tap for Zeek"
  network_interface_id = aws_instance.zeek_sensor[0].primary_network_interface_id
}

resource "aws_ec2_traffic_mirror_filter" "zeek_filter" {
  count = var.zeek_server.zeek_server == "1" ? 1 : 0
  description = "Zeek Mirror Filter - Allow All"
}

resource "aws_ec2_traffic_mirror_filter_rule" "zeek_outbound" {
  count = var.zeek_server.zeek_server == "1" ? 1 : 0
  description = "Zeek Outbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.zeek_filter[0].id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "egress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "zeek_inbound" {
  count = var.zeek_server.zeek_server == "1" ? 1 : 0
  description = "Zeek Inbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.zeek_filter[0].id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
}

resource "aws_ec2_traffic_mirror_session" "zeek_windows_session" {
  count                    = var.zeek_server.zeek_server == "1" ? length(var.windows_servers) : 0
  description              = "Zeek Mirror Session for Windows Server"
  depends_on               = [var.windows_server_instances]
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.zeek_filter[0].id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.zeek_target[0].id
  network_interface_id     = var.windows_server_instances[count.index].primary_network_interface_id
  session_number           = 100
}

resource "aws_ec2_traffic_mirror_session" "zeek_linux_session" {
  count                    = var.zeek_server.zeek_server == "1" ? length(var.linux_servers) : 0
  description              = "Zeek Mirror Session for Linux Server"
  depends_on               = [var.linux_server_instances]
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.zeek_filter[0].id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.zeek_target[0].id
  network_interface_id     = var.linux_server_instances[count.index].primary_network_interface_id
  session_number           = 100
}