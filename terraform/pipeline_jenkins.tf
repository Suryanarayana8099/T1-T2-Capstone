resource "aws_instance" "ci-capstone-jenkins" {
  instance_type          = var.jenkins_instance_type
  ami                    = lookup(var.aws_amis, var.aws_region)
  availability_zone      = var.availability_zone_2
  subnet_id              = aws_subnet.msaicharan_public_subnet_2.id
  key_name               = aws_key_pair.msaicharan_keypair.key_name
  vpc_security_group_ids = [aws_security_group.k8s-security-group.id]
  #iam_instance_profile = "${aws_iam_instance_profile.ec2_read_profile.name}"
  tags = {
    Name = "msaicharan-capstone-jenkins"
  }

  connection {
    user        = var.instance_user
    private_key = file("${var.private_key_path}")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "pipeline_config.tar"
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
      "sudo docker network create sonar-network",
      "sudo docker run -d --name sonar-db --network sonar-network -e POSTGRES_USER=sonar -e POSTGRES_PASSWORD=sonar -e POSTGRES_DB=sonar postgres:9.6",
      "sudo docker run -d --name sonar -p 9000:9000 --network sonar-network -e SONARQUBE_JDBC_URL=jdbc:postgresql://sonar-db:5432/sonar -e SONAR_JDBC_USERNAME=sonar -e SONAR_JDBC_PASSWORD=sonar sonarqube",
      "sudo rm -r /var/lib/jenkins/plugins /var/lib/jenkins/jobs /var/lib/jenkins/credentials.xml",
      "sudo tar -xvzf /home/ubuntu/jenkins_latest.tar -C /var/lib/jenkins",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/",
      "sudo systemctl restart jenkins",
      "sleep 200",
      "export public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)",
      "curl -u admin:admin -X POST 'http://localhost:9000/api/projects/create?name=capstone&project=capstone'",
      "curl -u admin:admin -X POST 'http://localhost:9000/api/webhooks/create' -d 'name=capstone_webhook&url=http://${aws_instance.ci-capstone-jenkins.public_ip}:8080/sonarqube-webhook&project=capstone'",
    ]
  }
  depends_on = [
    aws_subnet.msaicharan_public_subnet_2
  ]
}
