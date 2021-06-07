# Terraform-eks-bootstrap

##Initial steps.

* Pre-requirements.
    [Terraform 0.15.1](https://releases.hashicorp.com/terraform/0.15.1/)

* Environment variables needed to execute this deployment.
    1. AWS_ACCESS_KEY_ID=`<aws access key id>`
    2. AWS_REGION=`<aws region>`
    3. AWS_SECRET_ACCESS_KEY=`<aws access access id>`
    4. ENV=`<env>`


* Create Backend Bucket
    Bucket name: `project-terraform-state-<ENV>`
    Object name: `<ENV>/project-eks-bootstrap.tfstate`

* [Create Backend Dynamo Table](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)
    Table name: `<ENV>-project-terraform-state-lock-dynamo`
    Key: `LockID (string)`

