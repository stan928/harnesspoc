variable "additional_user_data_script" {
  description = "Additional user data script (default=\"\")"
  default     = ""
}

variable "asg_max_size" {
  description = "Maximum number EC2 instances"
  default     = 2
}

variable "asg_min_size" {
  description = "Minimum number of instances"
  default     = 1
}

variable "asg_desired_size" {
  description = "Desired number of instances"
  default     = 1
}

variable "image_id" {
  description = "AMI image_id for ECS instance"
  default     = ""
}

variable "instance_keypair" {
  description = "Instance keypair name"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC47IdjvZabKUVWr8wDLdkkOlFqsTRy58a8e+7UvPiXCx8AUxyGmljDm5vUFcVtcil2GdGVDZu6I81ivpTaXY8nZbtNh+bUpgbjVG8wevo6elMgO6VKR1ZEqNOTSnz83VXOki67ZLgdz7GASo5Qc3oFNlADvxTzqzlBkSeSXpy04TP5fjAWMaocdVGzOMfse831Pwl6rEHmlqE5rrhCYwaD3tirMyD2lA34p04fGRKiFxaSleF6IRqMexJOdkfzmfayYf1/wUvV6FNa74rmWlN50ljqLsBIFojomcLm1NJHEkB/g6CMAO/erqrZHvgNzur9e3bCLsrmnh9Q34uCKtSZ"
}

variable "instance_log_group" {
  description = "Instance log group in CloudWatch Logs"
  default     = ""
}

variable "instance_root_volume_size" {
  description = "Root volume size (default=50)"
  default     = 50
}

variable "instance_type" {
  description = "EC2 instance type (default=t2.micro)"
  default     = "t2.micro"
}

variable "name" {
  description = "Base name to use for resources in the module"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID to create cluster in"
}

variable "vpc_subnets" {
  description = "List of VPC subnets to put instances in"
}
