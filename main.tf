terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
 
provider "aws" {
  region = "ap-south-1"
}
 
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
 
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}
 
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-no-inbound-sg"
  description = "Outbound only for CloudWatch metrics"
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_instance" "monitored_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
 
  user_data = <<-EOT
              #!/bin/bash
              yes > /dev/null &
              yes > /dev/null &
              EOT
 
  tags = {
    Name = "Monitored-EC2-Instance"
  }
}
 
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "ec2-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggers when EC2 CPU exceeds 70%"
 
  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }
}
 
output "instance_id" {
  value = aws_instance.monitored_ec2.id
}
 
output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.high_cpu_alarm.alarm_name
}

