output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "private_web_subnet_id" {
  value = aws_subnet.private_web.id
}

output "private_storage_subnet_id" {
  value = aws_subnet.private_storage.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}
