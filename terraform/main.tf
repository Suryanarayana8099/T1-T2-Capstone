data "aws_subnets" "subnets_id" {
  filter {
    name   = "vpc-id"
    values = ["${var.vpc_id}"]
  }
}

resource "aws_security_group" "k8s-security-group" {
  name        = "msaicharan-k8s-security-group"
  vpc_id      = var.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = "true"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ci-capstone-k8s-master" {
  instance_type          = var.master_instance_type
  ami                    = lookup(var.aws_amis, var.aws_region)
  availability_zone      = var.availability_zone
  subnet_id              = "subnet-0a7e5cf063ea6e3a8"
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  key_name               = var.key_name
  tags = {
    Name = "msaicharan-capstone-k8s-master"
  }

  connection {
    user        = "ubuntu"
    private_key = file("${var.private_key_path}")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https curl ca-certificates gpg",
      "sudo mkdir -m 755 /etc/apt/keyrings",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-get install -y containerd",
      "sudo systemctl enable containerd",
      "sudo wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64",
      "sudo install -m 755 runc.amd64 /usr/local/sbin/runc",
      "sudo wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz",
      "mkdir -p /opt/cni/bin",
      "sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz",
      "cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf",
      "overlay",
      "br_netfilter",
      "EOF",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf",
      "net.bridge.bridge-nf-call-iptables = 1",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.ipv4.ip_forward = 1",
      "EOF",
      "sudo sysctl --system",
      "sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward",
      "modprobe br_netfilter",
      "sysctl -p /etc/sysctl.conf",
      "sudo kubeadm config images pull",
      "sudo kubeadm init",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml",
      "kubeadm token create --print-join-command > /tmp/join-command.txt",
      "cat /tmp/join-command.txt"
    ]
  }
}



resource "aws_instance" "ci-capstone-k8s-node" {
  instance_type          = var.node_instance_type
  count                  = var.node_count
  availability_zone      = var.availability_zone
  subnet_id              = "subnet-0a7e5cf063ea6e3a8"
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  ami                    = lookup(var.aws_amis, var.aws_region)
  key_name               = var.key_name
  tags = {
    Name = "msaicharan-capstone-k8s-node"
  }

  connection {
    user        = "ubuntu"
    type        = "ssh"
    private_key = file("${var.private_key_path}")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "msaicharan-key-pair.pem"
    destination = "/home/ubuntu/msaicharan-key-pair.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https curl ca-certificates gpg",
      "sudo mkdir -m 755 /etc/apt/keyrings",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf",
      "overlay",
      "br_netfilter",
      "EOF",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf",
      "net.bridge.bridge-nf-call-iptables = 1",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.ipv4.ip_forward = 1",
      "EOF",
      "sudo sysctl --system",
      "sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward",
      "modprobe br_netfilter",
      "sysctl -p /etc/sysctl.conf",
      "sudo apt-get update",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-get install -y containerd",
      "sudo systemctl enable containerd",
      "sudo chmod 400 /home/ubuntu/msaicharan-key-pair.pem",
      "cd /home/ubuntu/",
      "scp -o StrictHostKeyChecking=no -i ${var.private_key_path} ubuntu@${aws_instance.ci-capstone-k8s-master.public_ip}:/tmp/join-command.txt /tmp/join-command.txt",
      "sudo chmod +x /tmp/join-command.txt",
      "sudo bash /tmp/join-command.txt"
    ]
  }
  depends_on = [
    aws_instance.ci-capstone-k8s-master
  ]
}


resource "aws_instance" "ci-capstone-jenkins" {
  instance_type          = var.jenkins_instance_type
  ami                    = lookup(var.aws_amis, var.aws_region)
  availability_zone      = var.availability_zone
  subnet_id              = "subnet-0a7e5cf063ea6e3a8"
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  key_name               = var.key_name
  tags = {
    Name = "msaicharan-capstone-jenkins"
  }

  connection {
    user        = "ubuntu"
    private_key = file("${var.private_key_path}")
    host        = self.public_ip
  }
 provisioner "file" {
    source      = "jenkins_config.tar"
    destination = "/home/ubuntu/jenkins_latest.tar"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc",
      "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]  https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt update",
      "sudo apt install jenkins openjdk-17-jdk docker.io awscli -y",
      "echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers",
      "sudo systemctl start jenkins",
      "suoo docker network create sonar-network",
      "sudo docker run -d --name sonar-db --network sonar-network -e POSTGRES_USER=sonar -e POSTGRES_PASSWORD=sonar -e POSTGRES_DB=sonar postgres:9.6",
      "sudo docker run -d --name sonar -p 9000:9000 --network sonar-network -e SONARQUBE_JDBC_URL=jdbc:postgresql://sonar-db:5432/sonar -e SONAR_JDBC_USERNAME=sonar -e SONAR_JDBC_PASSWORD=sonar sonarqube",
      "sudo rm -r /var/lib/jenkins/plugins /var/lib/jenkins/jobs /var/lib/jenkins/credentials.xml",
      "sudo tar -xvzf /home/ubuntu/jenkins_latest.tar -C /var/lib/jenkins",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/",
      "sudo systemctl restart jenkins"

    ]
  }
}


resource "aws_lb" "ALB" {
  name               = "msaicharan-capstone-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.k8s-security-group.id}"]
  subnets = [data.aws_subnets.subnets_id.ids[0],
  data.aws_subnets.subnets_id.ids[1]]
}


resource "aws_lb_target_group" "Target_groups" {
  name        = "msaicharan-capstone-tg"
  target_type = "instance"
  vpc_id      = "vpc-07dc4f6ce63b0dbc1"
  port        = 80
  protocol    = "HTTP"
  health_check {
    path                = "/"
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
