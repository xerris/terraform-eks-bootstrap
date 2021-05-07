# terraform-eks-bootstrap
Initial steps.

1. Configure Control Tower environments
2. Generate keys for CI/CD
3. Create Backend Bucket
    Bucket name: `project-terraform-state-<ENV>`
    Object name: `<ENV>/project-eks-bootstrap.tfstate`
4. Create Backend Dynamo Table
    Table name: `<ENV>-project-terraform-state-lock-dynamo`
    Key: LockID (string)

