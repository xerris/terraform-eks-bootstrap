module "billing_alert" {
  source = "billtrust/billing-alarm/aws"
  aws_env = var.env
  monthly_billing_threshold = 500
  currency = "USD"
}

output "sns_topic" {
  value = "${module.billing_alert.sns_topic}"
}