#!/bin/bash
set -o nounset
set -o errexit


echo "###############################"
echo "## Starting Terraform script ##"
echo "###############################"

ENV="${ENV:-dev}"
AWS_REGION="${AWS_REGION:-ca-central-1}"
echo "Configuring AWS Profiles"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile kurbee-user
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile kurbee-user
aws configure set role_arn "arn:aws:iam::${ACCOUNT_ID}:role/deployment-role" --profile deployment-role
aws configure set source_profile kurbee-user --profile deployment-role
aws configure set role_session_name test-session --profile deployment-role
export AWS_PROFILE=deployment-role

APPLY=${1:-0} #If set terraform will force apply changes
commit_hash=`git rev-parse --short HEAD`
build_number="${BITBUCKET_BUILD_NUMBER:=local}"
#export TF_LOG=TRACE
export TF_VAR_commit_hash="${commit_hash}"
export TF_VAR_build_number="${build_number}"
echo $ACCOUNT_ID
echo $ENV
echo $AWS_REGION
terraform init \
-backend-config="bucket=project-eks-terraform-state-${ENV}" \
-backend-config="key=${ENV}/project-eks-bootstrap.tfstate" \
-backend-config="dynamodb_table=${ENV}-project-eks-terraform-state-lock-dynamo" \
-backend-config="region=${AWS_REGION}" \
-backend-config="role_arn=arn:aws:iam::${ACCOUNT_ID}:role/deployment-role" \
-backend-config="session_name=${ENV}-session"

terraform validate
terraform plan -var-file=envs/${ENV}.tfvars

if [ $APPLY == 2 ]; then
    echo "###############################"
    echo "## Executing terraform destroy ##"
    echo "###############################"
    terraform destroy --auto-approve -var-file=envs/${ENV}.tfvars
fi

if [ $APPLY == 1 ]; then
    echo "###############################"
    echo "## Executing terraform apply ##"
    echo "###############################"
    terraform apply --auto-approve -var-file=envs/${ENV}.tfvars
fi
