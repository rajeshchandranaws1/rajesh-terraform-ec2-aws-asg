resource "aws_launch_template" "template" {
  name_prefix     = "test"
  image_id        = "ami-0440d3b780d96b29d"
  instance_type   = "t2.micro"
  key_name        = "kp-mar4.pem"
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "test-autoscaling-group"  
  availability_zones    = ["us-east-1"]
  desired_capacity      = 1
  max_size              = 2
  min_size              = 1
  health_check_type     = "EC2"
  termination_policies  = ["OldestInstance"]

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

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_policy.arn]
  alarm_name          = "test_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "50"
  evaluation_periods  = "2"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscale.name
  }
}
