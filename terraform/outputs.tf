

output "master_address" {
  value = aws_instance.ci-sockshop-k8s-master.public_ip
}

output "Jenkins_address" {
  value = aws_instance.ci-sockshop-jenkins.public_ip
}

output "sock_shop_address" {
  value = aws_lb.ALB.dns_name
}
