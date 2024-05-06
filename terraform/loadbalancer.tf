resource "aws_lb" "ALB" {
  name               = "msaicharan-capstone-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.k8s-security-group.id}"]
  subnets            = [aws_subnet.msaicharan_public_subnet_1.id, aws_subnet.msaicharan_public_subnet_2.id]
}


resource "aws_lb_target_group" "Target_groups" {
  name        = "msaicharan-capstone-tg"
  target_type = "instance"
  vpc_id      = aws_vpc.msaicharan_vpc.id
  port        = 80
  protocol    = "HTTP"
  health_check {
    path                = "/sgpa"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}


resource "aws_lb_listener" "ALB_Listner" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Target_groups.arn
  }

}

resource "aws_lb_target_group_attachment" "target_atatch_tcp" {

  count            = var.node_count
  target_group_arn = aws_lb_target_group.Target_groups.arn
  target_id        = aws_instance.ci-capstone-k8s-node[count.index].id
  port             = 30001
  depends_on = [
    aws_instance.ci-capstone-k8s-node
  ]
}
