resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit Gateway connecting Management and Production VPCs"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${var.environment}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "mgmt_attachment" {
  subnet_ids         = var.mgmt_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.mgmt_vpc_id

  tags = {
    Name = "${var.environment}-tgw-mgmt-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod_attachment" {
  subnet_ids         = var.prod_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.prod_vpc_id

  tags = {
    Name = "${var.environment}-tgw-prod-attachment"
  }
}
