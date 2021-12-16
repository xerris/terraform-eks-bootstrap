# Terraform-eks-bootstrap

## Introduction
This bootstrap creates a VPC and subnets, an RDS database and optional bastion host for accessing EKS worker nodes, if required. It also includes a module for a Cloudwatch alarm and SNS topic for billing purposes as well as basic IAM permissions for the EKS cluster.

## Blueprint
![Blueprint](eks_diagram.png "blueprint")

## Pre-requisites.
 * [Terraform 0.15.1](https://releases.hashicorp.com/terraform/0.15.1/)
 * The  `.terraform-version` will be used by `tfenv` utility, also  `version.tf` works with `tfenv` . It will install if needed and switch to the Terrraform version specified.

* tfenv  0.15.5tfutils/tfenv

## Environment variables needed to execute this deployment.
| Name | Value | Description |
|------|---------|--------|
|AWS_ACCESS_KEY_ID| n/a | n/a |
|AWS_SECRET_ACCESS_KEY| n/a | n/a |
|AWS_REGION | ca-central-1| n/a |
|ENV|< env >|n/a|

## Backend Requirements
  The Backend is the configuration service used to storage the instant snapshot from the infrastucture created.
* Create Backend Bucket
    * Bucket name: `project-terraform-state-<ENV>`
    * Object name: `<ENV>/project-eks-bootstrap.tfstate`

* [Create Backend Dynamo Table](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)
    * Table name: `<ENV>-project-terraform-state-lock-dynamo`
    * Key: `LockID (string)`

## Execution Steps

* Clone Repo

  * git clone git@github.com:xerris/terraform-eks-bootstrap.git

  * cd terraform-eks-bootstrap

* Initialize the Environment Variables
    ```
    export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXX"
    export AWS_SECRET_ACCESS_KEY="YYYYYYYYYYYYYYYYYYYYYYYYY"
    export AWS_REGION="ca-central-1"
    #Dont for get to set ENV variable(as “dev“ or “stage“ or “prod“  )
    #We have 3 predefine templated inside folder envs
    export ENV="dev"
    ```

* Edit file  terraform-eks-bootstrap/terraform_exec.sh

    * Set the name of the S3 bucket and S3 Object name for your backend (Remeber AWS S3 bucket name is unique globally )

    * For example lets assume that the enviroment We want to deploy is dev you need to create a unique S3 bucket called `xerris-eks-terraform-state-dev ` and a DynamoDB table called `dev-xerris-eks-terraform-state-lock-dynamo`

    * Set the name of your DynamoDb table to control the locking for the state file.
        ```
        terraform init \
        -upgrade \
        -backend-config="bucket=xerris-eks-terraform-state-${ENV}" \
        -backend-config="key=${ENV}/xerris-eks-bootstrap.tfstate" \
        -backend-config="dynamodb_table=${ENV}-xerris-eks-terraform-state-lock-dynamo" \
        -backend-config="region=${AWS_REGION}"
        ```

    * In the case you want to test without dynamodb table, Just remove below line from file `terraform-eks-bootstrap/terraform_exec.sh`

        ```
        -backend-config="dynamodb_table=${ENV}-xerris-eks-terraform-state-lock-dynamo" \
        ```

    * The `terraform_exec.sh` script receives one parameter that indicates the action to be executed.
        ```
        0 = Executes a terraform plan
        1 = Executes a terraform apply
        2 = Executes a terraform destroy
        ```

    * Execute a Terraform Plan on the project folder

        ```
        bash  terraform_exec.sh 0
        ```

    * Execute a Terraform apply on the project folder

        ```
        bash  terraform_exec.sh 1
        ```

    * Execute a Terraform Destroy on the project folder

        ```
        bash  terraform_exec.sh 2
        ```