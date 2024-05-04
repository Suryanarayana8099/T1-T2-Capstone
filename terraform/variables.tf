
variable "aws_amis" {
  default = {

    "eu-central-1" = "ami-04f9a173520f395dd"

  }
}
variable "vpc_id" {
  default = "vpc-07dc4f6ce63b0dbc1"

}
variable "availability_zone" {
  default = "eu-central-1a"
}

variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "instance_user" {
  description = "The user account to use on the instances to run the scripts."
  default     = "ubuntu"
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "msaicharan-key-pair"
}

variable "master_instance_type" {
  description = "The instance type to use for the Kubernetes master."
  default     = "t3.medium"
}
variable "jenkins_instance_type" {
  description = "The instance type to use for the Kubernetes master"
  default     = "t3.medium"
}

variable "node_instance_type" {
  description = "The instance type to use for the Kubernetes nodes."
  default     = "t3.medium"
}

variable "node_count" {
  description = "The number of nodes in the cluster."
  default     = "2"
}

variable "private_key_path" {
  default     = "msaicharan-key-pair.pem"
}
