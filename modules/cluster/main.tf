terraform {
  required_version = ">= 0.11"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.name}"
#  capacity_providers = ["FARGATE"]
#  default_capacity_provider_strategy {
#    capacity_provider = "FARGATE"
#    weight = 1 
#  }
}

resource "aws_cloudwatch_log_group" "instance" {
  name = "${var.instance_log_group != "" ? var.instance_log_group : format("%s-instance", var.name)}"
  tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}

data "aws_iam_policy_document" "instance_policy" {
  statement {
    sid = "CloudwatchPutMetricData"

    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "InstanceLogging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.instance.arn}",
    ]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name   = "${var.name}-ecs-instance"
  path   = "/"
  policy = "${data.aws_iam_policy_document.instance_policy.json}"
}

resource "aws_iam_role" "ecs-instance-role" {
  name = "${var.name}-ecs-instance-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}



data "aws_iam_policy_document" "ecs-instance-policy" {
   statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ec2.amazonaws.com"]
  }
 }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role = "${aws_iam_role.ecs-instance-role.name}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "${var.name}-ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs-instance-role.id}"
  provisioner "local-exec" {
  command = "sleep 60"
 }
}

resource "aws_iam_role" "ecs-service-role" {
  name = "${var.name}-ecs-service-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = "${aws_iam_role.ecs-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs.amazonaws.com"]
  }
 }
}
#
#resource "aws_iam_role_policy_attachment" "ecs_policy" {
#  role       = "${aws_iam_role.instance.name}"
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
#}
#
#resource "aws_iam_role_policy_attachment" "instance_policy" {
#  role       = "${aws_iam_role.instance.name}"
#  policy_arn = "${aws_iam_policy.instance_policy.arn}"
#}
#
#resource "aws_iam_instance_profile" "instance" {
#  name = "${var.name}-instance-profile"
#  role = "${aws_iam_role.instance.name}"
#}

#resource "aws_security_group" "instance" {
#  name        = "${var.name}-container-instance"
#  description = "Security Group managed by Terraform"
#  vpc_id      = "${var.vpc_id}"
#  tags        = "${merge(var.tags, map("Name", format("%s-container-instance", var.name)))}"
#}
#
#resource "aws_security_group_rule" "instance_out_all" {
#  type              = "egress"
#  from_port         = 0
#  to_port           = 65535
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = "${aws_security_group.instance.id}"
#}

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_key_pair" "user" {
  count      = "${var.instance_keypair != "" ? 0 : 1}"
  key_name   = "${var.name}"
  public_key = "${var.instance_keypair}"
}
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-0d927e3ac55a7b26f"
  subnet_id              =  "${var.vpc_subnets}" #CHANGE THIS
  instance_type          = "t2.medium"
  iam_instance_profile   = "ecsInstanceRole" #CHANGE THIS
  vpc_security_group_ids = ["sg-0238c495b92e66485"] #CHANGE THIS
  key_name               = "chens117-harness" #CHANGE THIS
  ebs_optimized          = "false"
  source_dest_check      = "false"
  user_data              = "#!/bin/bash\n\n # Update all packages\n\nsudo yum update -y\nsudo yum install -y ecs-init\nsudo service docker start\nsudo start ecs\n#Adding cluster name in ecs config\necho ECS_CLUSTER=${var.name}>> /etc/ecs/ecs.config\ncat /etc/ecs/ecs.config | grep \"ECS_CLUSTER\""
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }

#  tags {
#    Name                   = "openapi-ecs-ec2_instance"
#}

  lifecycle {
    ignore_changes         = ["ami", "user_data", "subnet_id", "key_name", "ebs_optimized", "private_ip"]
  }
}

#data "template_file" "user_data" {
#  template = "${file("${path.module}/user_data.tpl")}"
#  vars = {
#	cl_name = "${var.name}"
#  }
#}
#resource "aws_launch_configuration" "instance" {
#  name_prefix          = "${var.name}-lc"
#  image_id             = "${var.image_id != "" ? var.image_id : data.aws_ami.ecs.id}"
#  instance_type        = "${var.instance_type}"
#  iam_instance_profile = "${aws_iam_instance_profile.instance.name}"
#  security_groups      = ["${aws_security_group.instance.id}"]
#  key_name             = "${var.instance_keypair != "" ? var.instance_keypair : element(concat(aws_key_pair.user.*.key_name, list("")), 0)}"
#
#  root_block_device {
#    volume_size = "${var.instance_root_volume_size}"
#    volume_type = "gp2"
#  }
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}

#resource "aws_autoscaling_group" "asg" {
#  name = "${var.name}-asg"
#
#  launch_configuration = "${aws_launch_configuration.instance.name}"
#  vpc_zone_identifier  = ["${var.vpc_subnets}"]
#  max_size             = "${var.asg_max_size}"
#  min_size             = "${var.asg_min_size}"
#  desired_capacity     = "${var.asg_desired_size}"
#
#  health_check_grace_period = 300
#  health_check_type         = "EC2"
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
