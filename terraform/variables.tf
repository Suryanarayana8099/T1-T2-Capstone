
variable "aws_amis" {
  default = {
    "eu-central-1" = "ami-04f9a173520f395dd"
  }
}
variable "availability_zone_1" {
  default = "eu-central-1a"
}
variable "availability_zone_2" {
  default = "eu-central-1b"
}
variable "aws_region" {
  default = "eu-central-1"
}

variable "instance_user" {
  default = "ubuntu"
}

variable "master_instance_type" {
  default = "t3.medium"
}
variable "jenkins_instance_type" {
  default = "t3.large"
}

variable "node_instance_type" {
  default = "t3.medium"
}

variable "node_count" {
  default = "2"
}

variable "private_key_path" {
  default = "private.pem"
}
