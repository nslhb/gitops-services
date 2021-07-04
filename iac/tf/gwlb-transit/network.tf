resource "aws_eip" "FGTPublicIP" {
  depends_on        = [aws_instance.fgtvm]
  vpc               = true
  network_interface = aws_network_interface.eth0.id
}

resource "aws_eip" "FGT2PublicIP" {
  depends_on        = [aws_instance.fgtvm2]
  vpc               = true
  network_interface = aws_network_interface.fgt2eth0.id
}

//  Gateway Load Balancer on FGT VPC to single FGT
resource "aws_lb" "gateway_lb" {
  name                             = "gatewaylb"
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true

  // AZ1
  subnet_mapping {
    subnet_id = "subnet-054352c001edfd21c"
  }

  // AZ2
  subnet_mapping {
    subnet_id = "subnet-0df89d7d66ed280cc"
  }
}

resource "aws_lb_target_group" "fgt_target" {
  name        = "fgttarget"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = "vpc-0faae4e9e3f1f232f"

  health_check {
    port     = 8008
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "fgt_listener" {
  load_balancer_arn = aws_lb.gateway_lb.id

  default_action {
    target_group_arn = aws_lb_target_group.fgt_target.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "fgtattach" {
  depends_on       = [aws_instance.fgtvm]
  target_group_arn = aws_lb_target_group.fgt_target.arn
  target_id        = data.aws_network_interface.eth1.private_ip
  port             = 6081
}
//
resource "aws_lb_target_group_attachment" "fgt2attach" {
  depends_on       = [aws_instance.fgtvm2]
  target_group_arn = aws_lb_target_group.fgt_target.arn
  target_id        = data.aws_network_interface.fgt2eth1.private_ip
  port             = 6081
}


resource "aws_vpc_endpoint_service" "fgtgwlbservice" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gateway_lb.arn]
}

# CS 1 Endpoint
resource "aws_vpc_endpoint" "gwlbendpoint" {
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = ["subnet-0d54b2e780165047b"]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = "vpc-082e04294c9380fe9"
}

# CS 2 Endpoint
resource "aws_vpc_endpoint" "gwlbendpoint2" {
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = ["subnet-0d59ca6e31f275462"]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = "vpc-0e0ccffca59ba6525"
}
