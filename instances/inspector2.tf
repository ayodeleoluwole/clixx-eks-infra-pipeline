# Enable Inspector2 for this account
resource "aws_inspector2_enabler" "inspector2" {
  account_ids = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR"]
}
