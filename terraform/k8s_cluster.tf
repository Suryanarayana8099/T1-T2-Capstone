resource "aws_instance" "ci-capstone-k8s-master" {
  instance_type          = var.master_instance_type
  ami                    = lookup(var.aws_amis, var.aws_region)
  availability_zone      = var.availability_zone_1
  subnet_id              = aws_subnet.msaicharan_public_subnet_1.id
  key_name               = aws_key_pair.msaicharan_keypair.key_name
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  tags = {
    Name = "msaicharan-capstone-k8s-master"
  }

  connection {
    user        = var.instance_user
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
  depends_on = [
    aws_instance.ci-capstone-jenkins
  ]
}



resource "aws_instance" "ci-capstone-k8s-node" {
  instance_type          = var.node_instance_type
  count                  = var.node_count
  availability_zone      = var.availability_zone_1
  subnet_id              = aws_subnet.msaicharan_public_subnet_1.id
  key_name               = aws_key_pair.msaicharan_keypair.key_name
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  ami                    = lookup(var.aws_amis, var.aws_region)

  tags = {
    Name = "msaicharan-capstone-k8s-node"
  }

  connection {
    user        = var.instance_user
    type        = "ssh"
    private_key = file("${var.private_key_path}")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "private.pem"
    destination = "/home/ubuntu/private.pem"
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
      "sudo chmod 400 /home/ubuntu/${var.private_key_path}",
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