// FGTVM instance AZ2

resource "aws_network_interface" "fgt2eth0" {
  description = "fgtvm2-port1"
  subnet_id   = "subnet-0900b6e43569f3975"
}

resource "aws_network_interface" "fgt2eth1" {
  description       = "fgtvm2-port2"
  subnet_id         = "subnet-0df89d7d66ed280cc"
  source_dest_check = false
}

data "aws_network_interface" "fgt2eth1" {
  id = aws_network_interface.fgt2eth1.id
}

//
data "aws_network_interface" "vpcendpointipaz2" {
  depends_on = [aws_vpc_endpoint.gwlbendpoint]
  filter {
    name   = "vpc-id"
    values = ["vpc-0faae4e9e3f1f232f"]
  }
  filter {
    name   = "status"
    values = ["in-use"]
  }
  filter {
    name   = "description"
    values = ["*ELB*"]
  }
  //  Using AZ1's endpoint ip
  filter {
    name   = "availability-zone"
    values = ["${var.az1}"]
  }
}

resource "aws_network_interface_sg_attachment" "fgt2publicattachment" {
  depends_on           = [aws_network_interface.fgt2eth0]
  security_group_id    = "sg-0c4222c05895954ee"
  network_interface_id = aws_network_interface.fgt2eth0.id
}

resource "aws_network_interface_sg_attachment" "fgt2internalattachment" {
  depends_on           = [aws_network_interface.fgt2eth1]
  security_group_id    = "sg-0635bbe901f993fcf"
  network_interface_id = aws_network_interface.fgt2eth1.id
}


resource "aws_instance" "fgtvm2" {
  ami               = var.license_type == "byol" ? var.fgtvmbyolami[var.region] : var.fgtvmami[var.region]
  instance_type     = var.size
  availability_zone = var.az2
  key_name          = var.keyname
  user_data         = templatefile(var.bootstrap-fgtvm2, {
    type         = var.license_type
    license_file = var.license2
    adminsport   = var.adminsport
    cidr         = "100.96.251.32/27"
    gateway      = cidrhost("100.96.251.160/27", 1)
    endpointip   = data.aws_network_interface.vpcendpointipaz2.private_ip
  })

  root_block_device {
    volume_type = "standard"
    volume_size = "2"
    encrypted = true
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "30"
    volume_type = "standard"
    encrypted = true
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt2eth0.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt2eth1.id
    device_index         = 1
  }

  tags = {
    Name = "FortiGateVM2"
  }

  lifecycle {
    ignore_changes = [
     instance_state
    ]
  }


}
