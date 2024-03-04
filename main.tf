resource "aws_launch_template" "template" {
  name_prefix     = "test"
  image_id        = "ami-1a2b3c"
  instance_type   = "t2.micro"
  security_groups = ["sg-12345678"]
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "test-autoscaling-group"  
  availability_zones    = ["us-east-1"]
  desired_capacity      = 1
  max_size              = 2
  min_size              = 1
  health_check_type     = "EC2"
  termination_policies  = ["OldestInstance"]
  vpc_zone_identifier   = ["subnet-12345678"]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_policy" {
  name                   = "test_scale_policy"
  autoscaling_group_name = aws_autoscaling_group.autoscale.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "test_scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "25"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscale.name
  }
}
