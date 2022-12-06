resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = "billing-alarm-USD-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "28800"
  statistic           = "Maximum"
  threshold           = "100"
  alarm_actions       = ["${aws_sns_topic.sns_alert_topic.arn}"]
  provider            = aws.use1
  dimensions = {
    Currency = "USD"
  }

}

resource "aws_sns_topic" "sns_alert_topic" {
  name     = "billing-alarm-notification-USD-${var.env}"
  provider = aws.use1
}


resource "aws_sns_topic_subscription" "ashu_email" {
  topic_arn = aws_sns_topic.sns_alert_topic.arn
  protocol  = "email"
  endpoint  = "ashu.sethi@xerris.com"
  provider  = aws.use1

}

resource "aws_sns_topic_subscription" "andres_email" {
  topic_arn = aws_sns_topic.sns_alert_topic.arn
  protocol  = "email"
  endpoint  = "andres.torres@xerris.com"
 provider  = aws.use1

}


provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
